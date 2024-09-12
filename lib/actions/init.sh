#!/usr/bin/env bash
action_init() {
    SPIN_TEMPLATE_TEMPORARY_SRC_DIR=${SPIN_TEMPLATE_TEMPORARY_SRC_DIR:-""}
    SPIN_USER_TODOS=${SPIN_USER_TODOS:-""}
    template_repository=${template_repository:-""}

    export SPIN_USER_TODOS

    if [ $# -lt 1 ]; then
        echo "${BOLD}${YELLOW}🤔 You didn't pass 'spin init' any templates that you want to initialize with. Run 'spin help' if you want to see the documentation.${RESET}"
        echo "Use official templates: spin init laravel"
        echo "Use a GitHub repo: spin init username/repo"
        exit 1
    fi
    download_spin_template_repository "$@"

    # Set the SPIN_ACTION to "init" if
    # "spin new" hasn't set an action already
    if [ -z "$SPIN_ACTION" ]; then
        SPIN_ACTION="init"
        export SPIN_ACTION
    fi
    # Check if the template has an init script and execute it
    if [ -f "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/install.sh" ]; then
        # Use source with the arguments passed individually
        set -- "${framework_args[@]}"
        source "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/install.sh" "$@"
    else
        echo "${BOLD}${RED}🛑 The '$template_repository' template does not contain a 'init.sh' script. Unable to install.${RESET}"
        exit 1
    fi
    
    if [ -z "$SPIN_PROJECT_DIRECTORY" ]; then
        echo "${BOLD}${RED}🛑 The 'SPIN_PROJECT_DIRECTORY' variable is not set. Unable to initialize.${RESET}"
        exit 1
    fi

    absolute_project_directory=$(realpath "$SPIN_PROJECT_DIRECTORY")

    create_config_folders "$absolute_project_directory/.infrastructure/volume_data"
    line_in_file --file "$absolute_project_directory/.gitignore" \
        ".vault-password"
    line_in_file --file "$absolute_project_directory/.dockerignore" \
        ".vault-password" \
        ".github" \
        ".git" \
        ".infrastructure" \
        "!.infrastructure/conf/traefik/dev/certificates/ssu-ca.pem" \
        "Dockerfile" \
        "docker-*.yml" \
        ".gitlab-ci.yml" \
        ".spin*" \

    copy_template_files "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/template" "$absolute_project_directory"

    # Download default config and inventory from GitHub
    get_file_from_github_release --repo "serversideup/ansible-collection-spin" --release-type "stable" --src ".spin-inventory.example.ini" --dest "$absolute_project_directory/.spin-inventory.ini"
    get_file_from_github_release --repo "serversideup/ansible-collection-spin" --release-type "stable" --src ".spin.example.yml" --dest "$absolute_project_directory/.spin.yml"
    prompt_to_encrypt_files --path "$absolute_project_directory" --file ".spin.yml" --file ".spin-inventory.ini"

    # Check if the template has a post-install script and execute it
    if [ -f "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/post-install.sh" ]; then
        source "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/post-install.sh"
    fi

    if [ -z "$SPIN_USER_TODOS" ]; then
        echo "${BOLD}${GREEN}🚀 Your project is now ready for \"spin up\"!${RESET}"
        echo "${BOLD}${YELLOW}👉 Learn how to use your template at https://github.com/$TEMPLATE_REPOSITORY${RESET}"
    else
        echo "${BOLD}${GREEN}🚀 Installation complete!${RESET}"
        echo "${BOLD}${BLUE} Some packages can't be installed automatically."
        echo "${BOLD}${BLUE} Please follow the instructions below to complete the installation."
        echo ""
        echo "${BOLD}${YELLOW}⚠️ FURTHER ACTION IS REQUIRED:"
        echo "$SPIN_USER_TODOS" | while IFS= read -r todo; do
            echo "  👉 $todo"
        done
        echo ""
        echo "${BOLD}${BLUE}Once you complete the above steps, your project will be ready for 'spin up' 🥳"
    fi

}