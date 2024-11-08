#!/usr/bin/env bash
action_provision(){
    local inventory_file="${SPIN_INVENTORY_FILE:-"/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh"}"
    
    prepare_ansible_args "$@"

    run_ansible --allow-ssh --mount-path "$(pwd)" \
        ansible-playbook serversideup.spin.provision \
        --inventory "$inventory_file" \
        --extra-vars @./.spin.yml \
        "${SPIN_ANSIBLE_ARGS[@]}" \
        "${SPIN_UNPROCESSED_ARGS[@]}"
}