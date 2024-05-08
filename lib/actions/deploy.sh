#!/usr/bin/env bash
action_deploy(){
    additional_ansible_args=""
    declare -a compose_files  # Declare an array to store Docker Compose files
    declare -a unprocessed_args
    target_environment=""
    ansible_user="$USER"  # Default to the current user
    force_ansible_upgrade=false
    
    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user|-u)
                ansible_user="$2"  # Override default user with specified user
                shift 2
                ;;
            --compose-file|-c)
                if [[ -n "$2" && "$2" != -* ]]; then
                    compose_files+=("$2")
                    shift 2
                else
                    echo "Error: '-c' option requires a Docker Compose file as argument."
                    exit 1
                fi
                ;;
            --port|-p)
                additional_ansible_args+=" --extra-vars ansible_portt=$2"
                shift 2
                ;;
            --upgrade|-u)
                force_ansible_upgrade=true
                shift
                ;;
            *)
                if [[ -z "$target_environment" ]]; then  # capture the first positional argument as environment
                    target_environment="$1"
                else
                    unprocessed_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    # Validate target environment
    if [[ -z "$target_environment" ]]; then
        echo "${BOLD}${YELLOW}You didn't pass 'spin deploy' an environment to deploy to. Run 'spin help' if you want to see the documentation.${RESET}"
        exit 1
    fi

    # Add environment and user to Ansible args
    additional_ansible_args+=" --extra-vars target=$target_environment"
    additional_ansible_args+="  --extra-vars ansible_user=$ansible_user"
    if [[ "$ansible_user" != "root" ]]; then
        additional_ansible_args+=" --ask-become-pass"
    fi

    # Handle Docker Compose files
    if [[ ${#compose_files[@]} -eq 0 ]]; then
        # Default files if none are specified
        compose_files=("docker-compose.yml" "docker-compose.prod.yml")
    fi

    # Convert array to a string separated by commas to pass to Ansible
    compose_files_str=$(IFS=,; echo "${compose_files[*]}")
    additional_ansible_args+=" --extra-vars compose_files='$compose_files_str'"

    # Run the Ansible playbook
    prepare_ansible_run
    run_ansible --allow-ssh --mount-path "$(pwd)" \
        ansible-playbook serversideup.spin.deploy \
        --inventory ./.spin-inventory.ini \
        --extra-vars @./.spin.yml \
        $additional_ansible_args \
        "${unprocessed_args[@]}"
}