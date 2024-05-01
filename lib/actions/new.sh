#!/usr/bin/env bash
action_new(){
  if [ $# -lt 1 ]; then
    printf "${BOLD}${YELLOW}\🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}"
    exit 1
  fi

  # Get extra arguments (if passed)
  for arg in "$@"; do
    case "$arg" in
      -b|--branch)
        branch="${2}"
        ;;
    esac
  done

  # Figure out what the user wants to create
  case $1 in
    laravel)
      shift 1
      echo "Official Laravel"
    ;;
    nuxt)
      shift 1
      echo "Official Nuxt"
    ;;
    *)
      repository_exsits_and_has_access $1

    ;;
  esac

}