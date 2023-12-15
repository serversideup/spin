#!/usr/bin/env bash
action_vault(){
    if [[ $1 == "edit" ]]; then

        if [[ -z $2 ]];then
            echo "${BOLD}${RED}❌ Please specify a file to edit.${RESET}"
            return 1
        fi

        echo "${BOLD}${YELLOW}ℹ️ We're using ansible-vault within the container to edit your file, which uses \"vi\".${RESET}"
        echo "${BOLD}${YELLOW}👉 To edit the file, press i.${RESET}"
        echo "${BOLD}${YELLOW}💾 To save your changes and exit, press ESC, then type \":wq\" and press ENTER.${RESET}"
    fi
    docker run --rm -it -v "$(pwd)":/ansible $SPIN_ANSIBLE_IMAGE ansible-vault "$@"
}