#!/usr/bin/env bash
action_provision(){
    if is_encrypted_with_ansible_vault ".spin.yml" && \
    [ ! -f ".vault-password" ]; then
        echo "${BOLD}${RED}❌Error: .spin.yml is encrypted with Ansible Vault, but '.vault-password' file is missing.${RESET}"
        echo "${BOLD}${YELLOW}Please save your vault password in '.vault-password' in your project root and try again.${RESET}"
        exit 1
    fi
    
    prepare_ansible_run "$@"
    run_ansible --set-env --allow-ssh --mount-path "$(pwd):/ansible" \
        ansible-playbook serversideup.spin.provision \
        --inventory "$SPIN_INVENTORY_FILE" \
        --extra-vars @./.spin.yml \
        "${SPIN_ANSIBLE_ARGS[@]}" \
        "${SPIN_UNPROCESSED_ARGS[@]}"
}