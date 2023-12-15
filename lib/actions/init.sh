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
      echo -n "${BOLD}${YELLOW}👉 Heads up: We're about to add our templates to your project.${RESET} Are you good with that? [y/n]: "
      read -n 1 add_files_response
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
      echo -n "Enter the number of your choice (1 for Laravel, 2 for Nuxt): "
      read -r project_type_number
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
    echo "${BOLD}${BLUE}⚡️ Copying spin templates to our project, \"$project_directory\"...${RESET}"

    # Check to see if the template file already exists in the project directory
    find "$SPIN_HOME/templates/$template" -type f -exec bash -c '
      for file do
        target_file="$2/${file#$1/}"
        if [[ -d "$file" ]]; then
          continue
        fi
        if [[ -f "$target_file" ]]; then
          echo "${BOLD}${YELLOW}⚠️  \"$target_file\" already exists. Skipping...${RESET}"
        else
          mkdir -p "$(dirname "$target_file")"
          if cp "$file" "$target_file"; then
            echo "${BOLD}${GREEN}✅ \"$target_file\" has been created.${RESET}"
          else
            echo "${BOLD}${RED}❌ Error copying \"$file\" to \"$target_file\".${RESET}"
          fi
        fi
      done
    ' bash "$SPIN_HOME/templates/$template" "$project_directory" {} +
  fi

  echo "${BOLD}${BLUE}⚡️ Adding items to your .gitignore for best security...${RESET}"

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if the line is not already in the .gitignore
    if ! grep -Fxq "$line" "$project_directory/.gitignore"; then
        # If the line is not in .gitignore, append it
        echo "$line" >> "$project_directory/.gitignore"
    fi
  done < "$SPIN_HOME/templates/common/.gitignore.example"

  if [[ -f "$project_directory/.spin.yml" ]]; then
    echo "${BOLD}${YELLOW}⚠️  \"$project_directory/.spin.yml\" already exists. Skipping...${RESET}"
  else
    echo "${BOLD}${BLUE}⚡️ Creating \"$project_directory/.spin.yml\"...${RESET}"
    cp "$SPIN_HOME/templates/common/.spin.example.yml" "$project_directory/.spin.yml"
  fi

  if [[ ! -f "$project_directory/.vault_password" ]]; then
    echo "${BOLD}${YELLOW}⚠️ Your \".spin.yml\" is not encrypted. We HIGHLY reccomend encrypting it. Would you like to encrypt it now?${RESET}"
    echo -n "Enter \"y\" or \"n\": "
    read -n 1 encrypt_response
    echo # move to a new line

    if [[ $encrypt_response =~ ^[Yy]$ ]]; then
      echo "${BOLD}${BLUE}⚡️ Running Ansible Vault to encrypt \"$project_directory/.spin.yml\"...${RESET}"
      echo "${BOLD}${YELLOW}⚠️ NOTE: This password will be required anytime someone needs to change the \".spin.yml\" file.${RESET}"
      echo "${BOLD}${YELLOW}We recommend using a RANDOM PASSWORD.${RESET}"
      docker run --name spin-ansible --rm --pull always -it -v "$(pwd)/$project_directory":/project -w /project $DEFAULT_ANSIBLE_IMAGE ansible-vault encrypt .spin.yml
      echo "${BOLD}${GREEN}✅ \"$project_directory/.spin.yml\" has been encrypted.${RESET}"
      echo "${BOLD}${YELLOW}👉 NOTE: You can save this password in \".vault_password\" in the root of your project if you want your secret to be remembered.${RESET}"
    elif [[ $encrypt_response =~ ^[Nn]$ ]]; then
      echo "${BOLD}${BLUE}👋 Ok, we won't encrypt your \".spin.yml\".${RESET} You can always encrypt it later by running \"spin vault encrypt\"."
    else
      echo "${BOLD}${RED}❌ Invalid response. Please respond with \"y\" or \"n\".${RESET} Run \"spin init\" to try again."
      return 1
    fi
  fi

  echo "${BOLD}${BLUE}🚀 The project, \"$project_name\", is now ready for \"spin  up\"!${RESET}"
}