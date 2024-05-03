#!/usr/bin/env bash
action_new() {
  local branch='' official_spin_template='' template_repository='' additional_args=()

  if [ $# -lt 1 ]; then
    printf "${BOLD}${YELLOW}🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}\n"
    exit 1
  fi

  cleanup() {
    rm -rf "$temp_dir"
  }

  # Argument parsing
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -b|--branch)
        branch="$2"
        shift 2  # Shift both the flag and its value
        ;;
      -*)
        echo "${BOLD}${RED}🛑 Unsupported flag ${1}.${RESET}"
        exit 1
        ;;
      *)
        args_without_options+=("$1")
        shift
        ;;
    esac
  done

  # First positional argument should be the template or template repository
  if [ ! -z "${args_without_options[0]}" ]; then
    template="${args_without_options[0]}"
    unset args_without_options[0]
  fi

  # Remaining positional arguments are additional args
  additional_args=("${args_without_options[@]}")

  # Determine the type of template
  case "$template" in
    laravel)
      official_spin_template=true
      template_repository="serversideup/spin-template-laravel"
      ;;
    nuxt)
      official_spin_template=true
      template_repository="serversideup/spin-template-nuxt"
      ;;
    *)
      official_spin_template=false
      template_repository="$template"
      ;;
  esac

  # Determine the branch to download
  [ -z "$branch" ] && branch=$(github_default_branch "$template_repository")

  # Check if the repository exists
  local download_url="https://github.com/$template_repository/archive/refs/heads/$branch.tar.gz"
  if ! curl --head --silent --fail "$download_url" &> /dev/null; then
    echo "${BOLD}${RED}🛑 Repository does not exist or you do not have access to it.${RESET}"
    echo ""
    echo "${BOLD}${YELLOW}👇Try running this yourself to debug access:${RESET}"
    echo "curl $download_url"
    echo ""
  fi

  # Third-party repository warning and confirmation
  if [[ "$official_spin_template" != true ]]; then
    echo "${BOLD}${YELLOW}⚠️ You're downloading content from a third party repository.${RESET}"

    display_repository_metadata "$template_repository" "$branch"
    echo "${BOLD}${BLUE}Make sure you trust the source of the repository before continuing.${RESET}"
    echo "Do you wish to continue? (y/n)"
    read -r -n 1 -p ""
    echo  # Move to a new line

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${BOLD}${RED}❌ Operation cancelled.${RESET}"
      exit 1
    fi
  fi

  echo "${BOLD}${YELLOW}🔄 Downloading template...${RESET}"
  temp_dir=$(mktemp -d)
  trap cleanup EXIT
  curl -sL "$download_url" | tar -xz -C "$temp_dir" --strip-components=1

  echo "${BOLD}${YELLOW}🏃‍♂️ Running 'new.sh' script...${RESET}"
  if [ -f "$temp_dir/new.sh" ]; then
    bash "$temp_dir/new.sh" "${additional_args[@]}"
  else
    echo "${BOLD}${RED}🛑 The template does not contain a 'new.sh' script. Unable to install.${RESET}"
    exit 1
  fi
}
