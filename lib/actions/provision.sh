#!/usr/bin/env bash
action_provision(){
    
    # Install the required Ansible roles
    run_ansible ansible-galaxy collection install serversideup.spin --upgrade

    # Run the playbook
    run_ansible ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --vault-password-file ./.vault-password \
        --extra-vars @./.spin.yml \
        "$@"
}