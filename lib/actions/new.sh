#!/usr/bin/env bash
action_new() {
  local branch='' template_type='' template_repository='' additional_args=()

  if [ $# -lt 1 ]; then
    printf "${BOLD}${YELLOW}🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}\n"
    exit 1
  fi

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
      template_type=official
      template_repository="serversideup/spin-template-laravel"
      ;;
    nuxt)
      template_type=official
      template_repository="serversideup/spin-template-nuxt"
      ;;
    *)
      template_type=external
      template_repository="$template"
      ;;
  esac

  # Determine the branch to download
  [ -z "$branch" ] && branch=$(github_default_branch "$template_repository")

  temp_dir=$(mktemp -d)
  trap cleanup_temp_repo_location EXIT
  download_template_repository  "$template_repository" "$branch" "$template_type" "$temp_dir"

  echo "${BOLD}${YELLOW}🏃‍♂️ Running 'new.sh' script...${RESET}"
  if [ -f "$temp_dir/new.sh" ]; then
    bash "$temp_dir/new.sh" "${additional_args[@]}"
  else
    echo "${BOLD}${RED}🛑 The template does not contain a 'new.sh' script. Unable to install.${RESET}"
    exit 1
  fi
}
