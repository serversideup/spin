#!/usr/bin/env bash
action_maintain(){
    validate_spin_yml

    echo "Preparing Ansible run..." >&2
    prepare_ansible_run "$@"

    # Check if there are any remaining unprocessed args
    # If so, use the first one as the target environment
    if [ ${#SPIN_UNPROCESSED_ARGS[@]} -gt 0 ]; then
        SPIN_ANSIBLE_ARGS+=("--extra-vars" "target=${SPIN_UNPROCESSED_ARGS[0]}")
        # Remove the first argument since we've processed it
        SPIN_UNPROCESSED_ARGS=("${SPIN_UNPROCESSED_ARGS[@]:1}")
    fi

    run_ansible --allow-ssh --mount-path "$(pwd):/ansible" \
        ansible-playbook serversideup.spin.maintain \
        --inventory "$SPIN_INVENTORY_FILE" \
        --extra-vars @./.spin.yml \
        "${SPIN_ANSIBLE_ARGS[@]}" \
        "${SPIN_UNPROCESSED_ARGS[@]}"
}