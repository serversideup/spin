#!/usr/bin/env bash
action_new(){
  # Check that an argument is passed
    if [ $# -gt 0 ]; then
      # Check the first argument and pass the user to proper action, Only some actions need arguments passed.
      case $1 in
        laravel)
          shift 1
          latest_image=$SPIN_PHP_IMAGE
          docker pull $latest_image
          docker run --rm -w /var/www/html -v $(pwd):/var/www/html --user "${SPIN_USER_ID}:${SPIN_GROUP_ID}" -e "LOG_LEVEL=off" $latest_image composer --no-cache create-project laravel/laravel "$@"
          install_spin_package_to_project php "${@:-laravel}" --force
          source "$SPIN_HOME/lib/actions/init.sh"
          action_init --template=laravel --project-directory="${@:-laravel}" --force
        ;;
        nuxt)
          shift 1
          latest_image=$SPIN_NODE_IMAGE
          docker pull $latest_image
          docker run --rm --user "${SPIN_USER_ID}:${SPIN_GROUP_ID}" -it -v $(pwd):/usr/src/app -w /usr/src/app $latest_image npx nuxi@latest init "$@"
          install_spin_package_to_project node "${@:-nuxt-app}" --force
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