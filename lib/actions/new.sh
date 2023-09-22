#!/usr/bin/env bash
action_new(){
  shift 1

  # Check that an argument is passed
    if [ $# -gt 0 ]; then
      # Check the first argument and pass the user to proper action, Only some actions need arguments passed.
      case $1 in
        laravel)
          shift 1
          docker run --rm -v $(pwd):/var/www/html -e "S6_LOGGING=1" serversideup/php:8.2-cli composer create-project laravel/laravel "$@"
        ;;
        *)
          echo "\"$1\" is not a valid command. Below are the commands available."
          action_help
        ;;
      esac
    else
      printf "${BOLD}${YELLOW}\🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}"
    fi

  }