#!/usr/bin/env bash
action_vault(){
    # Sanity check
    if [[ $1 == "edit" && -z $2 ]]; then
        echo "${BOLD}${RED}❌ Please specify a file to edit.${RESET}"
        return 1
    fi

    # Check if ansible-vault is installed locally
    if [[ $(command -v ansible-vault)  ]]; then
        vault_run_command="ansible-vault"
        run_type="local"
    else
        vault_run_command="docker run --rm -it -v $(pwd):/ansible $SPIN_ANSIBLE_IMAGE ansible-vault"
        run_type="docker"
    fi
    
    # Show notification for users running with Docker
    if [[ $run_type == "docker" && $1 == "edit" ]]; then
        echo "${BOLD}${YELLOW}ℹ️ You don't have ansible-vault installed locally."
        echo "${BOLD}${YELLOW}ℹ️ We'll use the container to edit your file, which uses \"vi\".${RESET}"
        echo "${BOLD}${YELLOW}👉 To edit the file, press i.${RESET}"
        echo "${BOLD}${YELLOW}💾 To save your changes and exit, press ESC, then type \":wq\" and press ENTER.${RESET}"
    fi

    $vault_run_command "$@"
}