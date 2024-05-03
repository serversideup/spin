#!/usr/bin/env bash
action_vault(){

    show_help() {
        $vault_run_command --help | sed 's/ansible-vault/spin vault/g'
    }

    # Check if ansible-vault is installed locally
    if [[ $(command -v ansible-vault)  ]]; then
        vault_run_command="ansible-vault"
        run_type="local"
    else
        vault_run_command="run_ansible --mount-path $(pwd) ansible-vault"
        run_type="docker"
    fi

    # Check if any argument is '--help'
    for arg in "$@"; do
        if [ "$arg" = "--help" ]; then
            show_help
            exit 0
        fi
    done

    # Sanity check
    if [[ -z $2 ]]; then
        echo "${BOLD}${RED}❌ Invalid command.${RESET}"
        show_help
        exit 1
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