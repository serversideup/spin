#!/usr/bin/env bash
action_provision(){
    additional_ansible_args=""
    
    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --user|-u)
                additional_ansible_args+=" --ask-become-pass --extra-vars ansible_user=$2"
                shift 2
                ;;
        esac
    done 

    prepare_ansible_run
    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $additional_ansible_args \
        "$@"
}