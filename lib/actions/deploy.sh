#!/usr/bin/env bash
action_deploy(){
    additional_ansible_args=""
    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --user|-u)
                additional_ansible_args+=" --ask-become-pass --extra-vars ansible_user=$2"
                shift 2
                ;;
            *)
                if [[ -z "$target_environment" ]]; then  # capture the first positional argument as environment
                    target_environment="$1"
                fi
                shift
                ;;
        esac
    done

    # Add target_environment to Ansible extra-vars
    if [[ -z "$target_environment" ]]; then
        echo "${BOLD}${YELLOW}🤔 You didn't pass \"spin deploy\" an environment to deploy to. Run \"spin help\" if you want to see the documentation.${RESET}"
        exit 1
    else
        additional_ansible_args+=" --extra-vars target=$target_environment"
    fi

    prepare_ansible_run
    run_ansible --allow-ssh --mount-path $(pwd) \
        ansible-playbook serversideup.spin.deploy \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $additional_ansible_args \
        "$@"
}