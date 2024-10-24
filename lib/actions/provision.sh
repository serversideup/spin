#!/usr/bin/env bash
action_provision(){
    additional_ansible_args=()
    ansible_user="$USER"  # Default to the current user who runs the command
    force_ansible_upgrade=false
    unprocessed_args=()
    
    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --user|-u)
                ansible_user="$2"  # Override default user with specified user
                shift 2
                ;;
            --port|-p)
                additional_ansible_args+=("--extra-vars ansible_port=$2")
                shift 2
                ;;
            --upgrade|-U)
                force_ansible_upgrade=true
                shift
                ;;
            *)
                unprocessed_args+=("$1")
                shift
                ;;
        esac
    done
    
    echo "Starting Ansible..."
    # Check if the Docker image exists and pull if it doesn't
    if ! docker image inspect "${SPIN_ANSIBLE_IMAGE}" &> /dev/null; then
        echo "Docker image ${SPIN_ANSIBLE_IMAGE} not found. Pulling..."
        docker pull "${SPIN_ANSIBLE_IMAGE}"
    fi

    # Set Ansible User
    additional_ansible_args+=("--extra-vars" "ansible_user=$ansible_user")
    local use_passwordless_sudo
    if ! use_passwordless_sudo=$(get_ansible_variable "use_passwordless_sudo"); then
        echo "${BOLD}${RED}❌ Error: Failed to get ansible variable.${RESET}" >&2
        exit 1
    fi
    use_passwordless_sudo=${use_passwordless_sudo:-"false"}
    if [ "$ansible_user" != "root" ] && [ "$use_passwordless_sudo" = 'false' ]; then
        additional_ansible_args+=("--ask-become-pass")
    fi

    # Append vault args to additional ansible args
    IFS=' ' read -r -a vault_args < <(set_ansible_vault_args)
    additional_ansible_args+=("${vault_args[@]}")

    check_galaxy_pull "$force_ansible_upgrade"
    run_ansible --allow-ssh --mount-path "$(pwd)" \
        ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        "${additional_ansible_args[@]}" \
        "${unprocessed_args[@]}"
}