#!/usr/bin/env bash
action_maintain(){
    additional_ansible_args=()
    spin_remote_user="$USER"  # Default to the current user who runs the command
    force_ansible_upgrade=false
    unprocessed_args=()
    local inventory_file="${SPIN_INVENTORY_FILE:-"/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh"}"
    
    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --host|-h)
                additional_ansible_args+=("--extra-vars" "target=$2")
                shift 2
                ;;
            --user|-u)
                spin_remote_user="$2"  # Override default user with specified user
                shift 2
                ;;
            --port|-p)
                additional_ansible_args+=("--extra-vars" "ansible_port=$2")
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
    additional_ansible_args+=("--extra-vars" "spin_remote_user=$spin_remote_user")
    local use_passwordless_sudo
    if ! use_passwordless_sudo=$(get_ansible_variable "use_passwordless_sudo"); then
        echo "${BOLD}${RED}❌ Error: Failed to get ansible variable.${RESET}" >&2
        exit 1
    fi
    use_passwordless_sudo=${use_passwordless_sudo:-"false"}
    if [ "$spin_remote_user" != "root" ] && [ "$use_passwordless_sudo" = 'false' ]; then
        additional_ansible_args+=("--ask-become-pass")
    fi

    # Append vault args to additional ansible args
    IFS=' ' read -r -a vault_args < <(set_ansible_vault_args)
    additional_ansible_args+=("${vault_args[@]}")

    check_galaxy_pull "$force_ansible_upgrade"
    run_ansible --allow-ssh --mount-path "$(pwd)" \
        ansible-playbook serversideup.spin.maintain \
        --inventory "$inventory_file" \
        --extra-vars @./.spin.yml \
        "${additional_ansible_args[@]}" \
        "${unprocessed_args[@]}"
}