#!/usr/bin/env bash
action_update() {
  
    if [ "$(installation_type)" == "user" ] && is_internet_connected; then
        check_for_upgrade --force
    else
      printf "${BOLD}${YELLOW}⚠️ Cannot automatically perform an update.${RESET} "
      printf "You're using \"spin\" from the project level or you're using spin in development mode.\n"
      printf "Use NPM/yarn or composer to update spin.\n"
      exit 1
    fi
}