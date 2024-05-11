#!/usr/bin/env bash
action_provision(){
    additional_ansible_args=()
    ansible_user="$USER"  # Default to the current user
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
                export force_ansible_upgrade
                shift
                ;;
            *)
                unprocessed_args+=("$1")
                shift
                ;;
        esac
    done

    # Set Ansible User
    additional_ansible_args+=("--extra-vars" "ansible_user=$ansible_user")
    if [[ "$ansible_user" != "root" ]]; then
        additional_ansible_args+=("--ask-become-pass")
    fi

    # Append vault args to additional ansible args
    IFS=' ' read -r -a vault_args < <(ansible_vault_args)
    additional_ansible_args+=("${vault_args[@]}")

    check_galaxy_pull
    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        "${additional_ansible_args[@]}" \
        "${unprocessed_args[@]}"
}