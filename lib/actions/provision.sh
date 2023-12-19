#!/usr/bin/env bash
action_provision(){
    if [[ -f .vault-password ]]; then
        additional_ansible_args="--vault-password-file .vault-password"
    elif is_encrypted_with_ansible_vault ".spin.yml" && is_encrypted_with_ansible_vault ".spin-inventory.ini"; then
        additional_ansible_args="--ask-vault-password"
    else
        additional_ansible_args=""
    fi
    
    # Install the required Ansible roles
    run_ansible ansible-galaxy collection install serversideup.spin --upgrade

    # Run the playbook
    run_ansible ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $additional_ansible_args \
        "$@"
}