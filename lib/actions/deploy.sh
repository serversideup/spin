#!/usr/bin/env bash
action_deploy(){
    additional_ansible_args=""
    remote_user_arg=""

    prepare_ansible_run  

    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-playbook serversideup.spin.provision \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $remote_user_arg \
        $additional_ansible_args \
        "$@"
}