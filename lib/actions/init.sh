#!/usr/bin/env bash
action_init() {
    set -e
    force=0
    project_directory="."
    spin_templates_directory="$SPIN_HOME/templates"

    for arg in "$@"; do
        case $arg in
            --force)
                force=1
                ;;
            --template=*)
                template="${arg#*=}"
                ;;
            --project-directory=*)
                project_directory="${arg#*=}"
                ;;
            *)
                echo "${BOLD}${RED}❌ Invalid argument: $arg ${RESET}"
                return 1
                ;;
        esac
    done

    # Assume we're in the project root if we can find a composer.json file or a package.json file
    if [[ ! -f "$project_directory/composer.json" && ! -f "$project_directory/package.json" ]]; then
        echo "${BOLD}${RED}❌ Unable to find a composer.json or package.json file in \"$project_directory\". Please run \"spin init\" from the root of your project.${RESET}"
        return 1
    fi

    copy_template_files(){
        local template_src="$1"
        additional_find_args=''

        # If the templates are not specifically looking for .github, then be sure to ignore GitHub
        if [[ $template_src != *".github"* ]]; then
            additional_find_args="-type d -name .github -prune -o"
            prepend_path=''
        else
            prepend_path='.github/'
        fi

        if [[ -d "$spin_templates_directory/$template_src" ]]; then
            # Check to see if the template file already exists in the project directory
            while IFS= read -r file; do
                # Skip files that end with .lineinfile and directories
                if [[ "$file" == *".lineinfile" ]] || [[ -d "$file" ]]; then
                    continue
                fi

                target_file="$project_directory/$prepend_path${file#"$spin_templates_directory/$template_src/"}"
                # Compute the relative path for the echo statements
                relative_target_file="${target_file#"$project_directory"/}"

                if [[ -f "$target_file" ]]; then
                    echo "👉 \"$relative_target_file\" already exists. Skipping..."
                else
                    mkdir -p "$(dirname "$target_file")"
                    if cp "$file" "$target_file"; then
                        echo "✅ \"$relative_target_file\" has been created."
                    else
                        echo "${BOLD}${RED}❌ Error copying \"$file\" to \"$relative_target_file\"."
                    fi
                fi
            done < <(find "$spin_templates_directory/$template_src" $additional_find_args -type f -print)

        else
            echo "${BOLD}${RED}❌ Invalid template: $template_src ${RESET}"
            return 1
        fi
    }

    ensure_line_is_in_file(){
        local source_file="$1"
        local dest_file="$2"

        while IFS= read -r line || [[ -n "$line" ]]; do
            if ! grep -Fxq "$line" "$dest_file" 2>/dev/null; then
                printf "%s\n" "$line" >> "$dest_file"
                file_name="${dest_file#"$project_directory/"}"
                echo "✅ \"$line\" has been added to \"$file_name\"."
            fi
        done < "$source_file"
    }

    encrypt_files_if_needed(){
        local files_to_encrypt=()

        for file in "$@"; do
            if ! is_encrypted_with_ansible_vault "$file"; then
                files_to_encrypt+=("$file")
            fi
        done

        if [ ${#files_to_encrypt[@]} -ne 0 ]; then
            echo "${BOLD}${YELLOW}⚠️ Your Spin configurations are not encrypted. We HIGHLY recommend encrypting it. Would you like to encrypt it now?${RESET}"
            echo -n "Enter \"y\" or \"n\": "
            read -r -n 1 encrypt_response
            echo # move to a new line

            if [[ $encrypt_response =~ ^[Yy]$ ]]; then
                echo "${BOLD}${BLUE}⚡️ Running Ansible Vault to encrypt Spin configurations...${RESET}"
                echo "${BOLD}${YELLOW}⚠️ NOTE: This password will be required anytime someone needs to change these files.${RESET}"
                echo "${BOLD}${YELLOW}We recommend using a RANDOM PASSWORD.${RESET}"
                
                # Encrpyt with Ansible Vault
                run_ansible ansible-vault encrypt "${files_to_encrypt[@]}"

                # Ensure the files are owned by the current user
                docker run --rm --platform linux/amd64 -v "$(pwd)/$project_directory:/ansible" $SPIN_ANSIBLE_IMAGE chown "${SPIN_USER_ID}:${SPIN_GROUP_ID}" /ansible/.spin.yml /ansible/.spin-inventory.ini
                echo "${BOLD}${YELLOW}👉 NOTE: You can save this password in \".vault-password\" in the root of your project if you want your secret to be remembered.${RESET}"
            elif [[ $encrypt_response =~ ^[Nn]$ ]]; then
                echo "${BOLD}${BLUE}👋 Ok, we won't encrypt these files.${RESET} You can always encrypt it later by running \"spin vault encrypt\"."
            else
                echo "${BOLD}${RED}❌ Invalid response. Please respond with \"y\" or \"n\".${RESET} Run \"spin init\" to try again."
                exit 1
            fi
        fi
    }

    ############################################
    # 🚀 Main Part of function
    ############################################
    if [[ $force = 0 ]]; then
        echo "${BOLD}${YELLOW}👉 Heads up: We're about to add our templates to your project.${RESET}"
        echo -n "Do you want to continue? [y/n]: "
        read -r -n 1 add_files_response
        echo  # move to a new line
        if [[ $add_files_response =~ ^[Yy]$ ]]; then
            echo "We will add our templates to your project."
        elif [[ $add_files_response =~ ^[Nn]$ ]]; then
            echo "${BOLD}${BLUE}👋 Ok, we won't add any files to your project.${RESET} You can always configure your infrastructure manually or run \"spin init\" again in the future."
            exit 2
        else
            echo "${BOLD}${RED}❌ Invalid response. Please respond with \"y\" or \"n\".${RESET} Run \"spin init\" to try again."
            return 1
        fi

        if [[ -z $template ]]; then
            echo "Select your project type:"
            echo "1) Laravel"
            echo "2) Nuxt"
            echo -n "Enter the number of your choice: "
            read -r -n 1 project_type_number
            echo # move to a new line

            case $project_type_number in
                1)
                    template="laravel"
                    ;;
                2)
                    template="node"
                    ;;
                *)
                    echo "Invalid selection."
                    return 1
                    ;;
            esac
        fi
    fi

    # Copy template files
    copy_template_files "common"
    copy_template_files "$template"

    # Ensure any "*.lineinfile" files have their lines in the destination file
    while IFS= read -r file; do
        source_path="$file"  # 'find' gives the full path, so you don't need to append the directory here.
        dest_file_name=$(basename "${file%.lineinfile}")  # Get the file name without the directory and suffix.
        dest_path="$project_directory/$dest_file_name"  # Construct the destination file path.
        ensure_line_is_in_file "$source_path" "$dest_path"
    done < <(find "$spin_templates_directory/common" -type f -name '*.lineinfile')

    if [[ $use_gha_templates = 1 ]]; then
        copy_template_files "$template/.github"
        update_templates_with_domain_name "$domain_name"
    fi

    # Download default config and inventory from GitHub
    get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin-inventory.example.ini" "$project_directory/.spin-inventory.ini"
    get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin.example.yml" "$project_directory/.spin.yml"

    # Encrypt files if needed
    encrypt_files_if_needed "$project_directory/.spin.yml" "$project_directory/.spin-inventory.ini"

    echo "${BOLD}${GREEN}🚀 Your project is now ready for \"spin up\"!${RESET}"
}