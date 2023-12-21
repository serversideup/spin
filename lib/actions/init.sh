#!/usr/bin/env bash
action_init() {
  set -e
  local force=0
  local project_directory="$(pwd)"

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

  if [[ -d "$SPIN_HOME/templates/$template" ]]; then
    echo "⚡️ Copying spin templates to our project..."

  # Check to see if the template file already exists in the project directory
  while IFS= read -r file; do
      target_file="$project_directory/${file#$SPIN_HOME/templates/$template/}"
      # Compute the relative path for the echo statements
      relative_target_file="${target_file#$project_directory/}"

      if [[ -d "$file" ]]; then
          continue
      fi
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
  done < <(find "$SPIN_HOME/templates/$template" -type d -name '.github' -prune -o -type f -print)

  fi

  # Ensure .gitignore exists and includes line in file
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if the line is not already in the .gitignore
    if ! grep -Fxq "$line" "$project_directory/.gitignore"; then
        # If the line is not in .gitignore, append it
        echo "$line" >> "$project_directory/.gitignore"
        echo "✅ \"$line\" has been added to \".gitignore\"."
    fi
  done < "$SPIN_HOME/templates/common/.gitignore.lineinfile"

  # Copy common files
  while IFS= read -r file; do
      # Skip files that end with .lineinfile
      if [[ "$file" == *".lineinfile" ]]; then
          continue
      fi

      target_file="$project_directory/${file#$SPIN_HOME/templates/common/}"
      # Compute the relative path for the echo statements
      relative_target_file="${target_file#$project_directory/}"

      if [[ -d "$file" ]]; then
          continue
      fi
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
  done < <(find "$SPIN_HOME/templates/common" -type f)

  # Download default config and inventory from GitHub
  get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin-inventory.example.ini" "$project_directory/.spin-inventory.ini"
  get_file_from_github_release "serversideup/ansible-collection-spin" "stable" ".spin.example.yml" "$project_directory/.spin.yml"

  # Encrpytion check
  if ! is_encrypted_with_ansible_vault "$project_directory/.spin.yml" || ! is_encrypted_with_ansible_vault "$project_directory/.spin-inventory.ini"; then
    echo "${BOLD}${YELLOW}⚠️ Your Spin configurations are not encrypted. We HIGHLY recommend encrypting it. Would you like to encrypt it now?${RESET}"
    echo -n "Enter \"y\" or \"n\": "
    read -r -n 1 encrypt_response
    echo # move to a new line

    if [[ $encrypt_response =~ ^[Yy]$ ]]; then
      echo "${BOLD}${BLUE}⚡️ Running Ansible Vault to encrypt Spin configurations...${RESET}"
      echo "${BOLD}${YELLOW}⚠️ NOTE: This password will be required anytime someone needs to change these files.${RESET}"
      echo "${BOLD}${YELLOW}We recommend using a RANDOM PASSWORD.${RESET}"
      run_ansible ansible-vault encrypt $project_directory/.spin.yml $project_directory/.spin-inventory.ini
      echo "${BOLD}${YELLOW}👉 NOTE: You can save this password in \".vault-password\" in the root of your project if you want your secret to be remembered.${RESET}"
    elif [[ $encrypt_response =~ ^[Nn]$ ]]; then
      echo "${BOLD}${BLUE}👋 Ok, we won't encrypt your \".spin.yml\".${RESET} You can always encrypt it later by running \"spin vault encrypt\"."
    else
      echo "${BOLD}${RED}❌ Invalid response. Please respond with \"y\" or \"n\".${RESET} Run \"spin init\" to try again."
      exit 1
    fi
  fi

  echo "${BOLD}${GREEN}🚀 Your project is now ready for \"spin  up\"!${RESET}"
}