#!/usr/bin/env bash
action_init() {
    SPIN_TEMPLATE_TEMPORARY_SRC_DIR=${SPIN_TEMPLATE_TEMPORARY_SRC_DIR:-""}
    template_repository=${template_repository:-""}

    if [ $# -lt 1 ]; then
        echo "${BOLD}${YELLOW}🤔 You didn't pass 'spin init' any templates that you want to initialize with. Run 'spin help' if you want to see the documentation.${RESET}"
        echo "Use official templates: spin init laravel"
        echo "Use a GitHub repo: spin init username/repo"
        exit 1
    fi

    download_spin_template_repository  "$@"

    # Set the SPIN_ACTION to "init" if
    # "spin new" hasn't set an action already
    if [ -z "$SPIN_ACTION" ]; then
        SPIN_ACTION="init"
        export SPIN_ACTION
    fi

    # Check if the template has an init script and execute it
    if [ -f "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/install.sh" ]; then
        shift # Fix to remove repository arguments
        source "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/install.sh" "${framework_args[@]}"
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
    ensure_lines_in_file "$absolute_project_directory/.gitignore" \
        ".vault-password"
    ensure_lines_in_file "$absolute_project_directory/.dockerignore" \
        ".vault-password" \
        ".github" \
        ".git" \
        ".infrastructure" \
        "Dockerfile" \
        "docker-*.yml" \
        ".gitlab-ci.yml"

    copy_template_files "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/template" "$absolute_project_directory"

    # Download default config and inventory from GitHub
    get_file_from_github_release --repo "serversideup/ansible-collection-spin" --release-type "stable" --src ".spin-inventory.example.ini" --dest "$absolute_project_directory/.spin-inventory.ini"
    get_file_from_github_release --repo "serversideup/ansible-collection-spin" --release-type "stable" --src ".spin.example.yml" --dest "$absolute_project_directory/.spin.yml"
    prompt_to_encrypt_files --path "$absolute_project_directory" --file ".spin.yml" --file ".spin-inventory.ini"

    # Check if the template has a post-install script and execute it
    if [ -f "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/post-install.sh" ]; then
        source "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/post-install.sh"
    fi

    echo "${BOLD}${GREEN}🚀 Your project is now ready for \"spin up\"!${RESET}"

    echo "${BOLD}${YELLOW}👉 Learn how to use your template at https://github.com/$TEMPLATE_REPOSITORY"

}