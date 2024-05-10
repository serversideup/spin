#!/usr/bin/env bash
action_init() {
    set -e
    local project_dir="${project_dir:-$(pwd)}"

    if [ $# -lt 1 ]; then
        printf "${BOLD}${YELLOW}🤔 You didn't pass \"spin init\" any templates that you want to initialize with. Run \"spin help\" if you want to see the documentation.${RESET}\n"
        echo "Use official templates: spin init laravel"
        echo "Use a GitHub repo: spin init username/repo"
        exit 1
    fi

    parse_repository_arguments "$@"

    if [[ "$template_download_complete" != true ]]; then
        download_template_repository  "$template_repository" "$branch" "$template_type"
    fi
    
    create_config_folders "$project_dir/.infrastructure/volume_data"
    ensure_lines_in_file "$project_dir/.gitignore" \
        ".vault-password"
    ensure_lines_in_file "$project_dir/.dockerignore" \
        ".vault-password" \
        ".github" \
        ".git" \
        ".infrastructure" \
        "Dockerfile" \
        "docker-*.yml" \
        ".gitlab-ci.yml"

    copy_template_files "$temp_dir/template" "$project_dir"

    # Download default config and inventory from GitHub
    get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin-inventory.example.ini" "$project_dir/.spin-inventory.ini"
    get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin.example.yml" "$project_dir/.spin.yml"
    prompt_to_encrypt_files "$project_dir/.spin.yml" "$project_dir/.spin-inventory.ini"

    echo "${BOLD}${GREEN}🚀 Your project is now ready for \"spin up\"!${RESET}"

    echo "${BOLD}${YELLOW}👉 Learn how to use your template at https://github.com/$template_repository"

}