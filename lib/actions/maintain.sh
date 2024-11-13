#!/usr/bin/env bash
action_maintain(){   
    prepare_ansible_run "$@"
    run_ansible --allow-ssh --mount-path "$(pwd):/ansible" \
        ansible-playbook serversideup.spin.maintain \
        --inventory "$SPIN_INVENTORY_FILE" \
        --extra-vars @./.spin.yml \
        "${SPIN_ANSIBLE_ARGS[@]}" \
        "${SPIN_UNPROCESSED_ARGS[@]}"
}