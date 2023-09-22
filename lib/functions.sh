#!/usr/bin/env bash

SPIN_CONFIG_FILE_LOCATION="$SPIN_HOME/conf/spin.conf"

check_for_upgrade() {
  # Perform upgrades when not within update threshold, or if "--force" is passed
  if ! is_within_update_threshold || [ "$1" == "--force" ] ; then
    send_to_upgrade_script
  else
    # Silence is golden. We won't bug the user if everything looks good.
    :
  fi
}

current_time_minus() {
  # Accepts parameters: The first passed argument should be the number of days to subtract
  # This will return a value of (current epoch time - number of days)

  local days_to_subtract
  days_to_subtract=$1
  
  # Check the OS, because the commands are different.
  case "$(uname -s)" in
    Linux*)     DATE_THRESHOLD=$(date -d "now - ${days_to_subtract} days" +%s);;
    Darwin*)    DATE_THRESHOLD=$(date -v -${days_to_subtract}d +%s);;
    *)          echo "We're unsure how to calculate a date on your operating system." && exit 2
  esac

  echo $DATE_THRESHOLD

}

docker_pull_check() {
  # Check for Internet connection before running a Docker pull
  if is_internet_connected; then

    if [ "$1" == "--no-pull" ]; then
      printf "${BOLD}${YELLOW}❗️ Skipping automatic docker image pull.${RESET}\n"
      shift 1
      PULL_PROCESSED_COMMANDS="$@"
      return
    fi
    $COMPOSE pull --ignore-pull-failures
    PULL_PROCESSED_COMMANDS="$@"
  else
      printf "${BOLD}${YELLOW}❗️ Skipping automatic docker image pull.${RESET}\n"
      PULL_PROCESSED_COMMANDS="$@"
  fi

  return
}

is_within_update_threshold() {
  if [ -f "$SPIN_HOME/cache/last_update_check.lock" ]; then
    if (( $(cat "$SPIN_HOME/cache/last_update_check.lock") <= $(current_time_minus "$AUTO_UPDATE_INTERVAL_IN_DAYS") )); then
      return 1
    else
      return 0
    fi
  else
    return 1
  fi
}


is_installed_to_user() {
  if [ -f "$SPIN_HOME/conf/spin.conf" ]; then
    return 0
  else
    return 1
  fi
}

is_internet_connected() {
  local response
  response=$(curl https://github.com/serversideup/spin/ --write-out %{http_code} --silent --output /dev/null --max-time 1)

  if [ $response -eq 200 ]; then
    return 0
  else
    printf "${BOLD}${YELLOW}\"spin\" tried to check for updates, but we couldn't connect to Github.com. We'll try again tomorrow.${RESET} \n"
    # Take the current time and subtract just one day short of the auto update interval so we check again tomorrow
    echo $(current_time_minus $(expr $AUTO_UPDATE_INTERVAL_IN_DAYS - 1)) > $SPIN_HOME/conf/last_update_check.lock
    return 1
  fi
}

print_version() {

  # Use the local Git repo to show our version
  printf "${BOLD}${YELLOW}Spin Version:${RESET} \n"
  printf "$(git -C $SPIN_HOME describe --tags) "
  
  # Show the track (if installed to the user)
  if is_installed_to_user; then
    source $SPIN_CONFIG_FILE_LOCATION
    printf "[$TRACK] "
    printf "(User Installed)\n"
  else
    printf "(Project Installed)\n"
  fi
}

send_to_upgrade_script () {
  if is_internet_connected; then
    source $SPIN_HOME/tools/upgrade.sh
  fi
}

setup_color() {
    RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
    "
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
}