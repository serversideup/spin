#!/usr/bin/env bash
action_provision(){
    additional_ansible_args=""
    remote_user_arg=""

    # Check if vault password exists
    if [[ -f .vault-password ]]; then
        additional_ansible_args="--vault-password-file .vault-password"
    elif is_encrypted_with_ansible_vault ".spin.yml" && is_encrypted_with_ansible_vault ".spin-inventory.ini"; then
        additional_ansible_args="--ask-vault-password"
    fi

    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --user|-u)
                remote_user_arg="--ask-become-pass --extra-vars ansible_user=$2"
                shift 2
                ;;
        esac
    done
    
    # Install the required Ansible roles
    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-galaxy collection install serversideup.spin --upgrade

    # Run the playbook
    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $remote_user_arg \
        $additional_ansible_args \
        "$@"
}