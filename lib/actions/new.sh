#!/usr/bin/env bash
action_new(){
  # Check that an argument is passed
    if [ $# -gt 0 ]; then
      # Check the first argument and pass the user to proper action, Only some actions need arguments passed.
      case $1 in
        laravel)
          shift 1
          latest_image=$(get_latest_image php)
          docker pull $latest_image
          docker run --rm -v $(pwd):/var/www/html -e "LOG_LEVEL=off" $latest_image composer create-project laravel/laravel "$@"
          add_spin_to_project php ${@:-laravel}
        ;;
        nuxt)
          shift 1
          latest_image=$(get_latest_image node)
          docker pull $latest_image
          docker run --rm -it -v $(pwd):/usr/src/app -w /usr/src/app $latest_image npx nuxi@latest init "$@"
          add_spin_to_project node ${@:-"nuxt-app"}
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