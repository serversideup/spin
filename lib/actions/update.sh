#!/usr/bin/env bash
action_update() {
  if is_installed_to_user; then

    if is_internet_connected; then
      check_for_upgrade --force
    fi

  else
    printf "${BOLD}${YELLOW}⚠️ Cannot automatically perform an update.${RESET} "
    printf "Your using \"spin\" from the project level. Install updates via NPM or Composer instead.\n"
    exit 1
  fi
}
