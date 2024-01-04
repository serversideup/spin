#!/usr/bin/env bash
action_latest(){  
  # Check that an argument is passed
    if [ $# -gt 0 ]; then
      # Check the first argument and pass the user to proper action, Only some actions need arguments passed.
      case $1 in
        node)
          shift 1
          docker run --rm -v $(pwd):/usr/app/src/ -w /usr/src/app $SPIN_NODE_IMAGE "$@"
        ;;
        php)
          shift 1
          docker run --rm -v $(pwd):/var/www/html $SPIN_PHP_IMAGE "$@"
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