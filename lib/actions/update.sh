#!/usr/bin/env bash
action_update() {
    if is_installed_to_user && not_in_active_development && is_internet_connected; then
        check_for_upgrade --force
    else
      printf "${BOLD}${YELLOW}⚠️ Cannot automatically perform an update.${RESET} "
      printf "You're using \"spin\" from the project level or you're in active development. Install updates via NPM or Composer instead.\n"
      exit 1
    fi
}