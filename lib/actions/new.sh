#!/usr/bin/env bash
action_new() {
  local branch='' template_type='' template_repository='' temp_dir='' project_dir='' additional_args=()

  if [ $# -lt 1 ]; then
    printf "${BOLD}${YELLOW}🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}\n"
    exit 1
  fi

  parse_repository_arguments "$@"
  download_template_repository  "$template_repository" "$branch" "$template_type"

  echo "${BOLD}${YELLOW}🏃‍♂️ Running 'new.sh' script...${RESET}"
  if [ -f "$temp_dir/new.sh" ]; then
    shift # Fix to remove repository arguments
    source "$temp_dir/new.sh" "${additional_args[@]}"
  else
    echo "${BOLD}${RED}🛑 The template does not contain a 'new.sh' script. Unable to install.${RESET}"
    exit 1
  fi
  action_init "$template_repository" --path "$project_dir"
}
