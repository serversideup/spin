#!/usr/bin/env bash

SPIN_CONFIG_FILE_LOCATION="$SPIN_HOME/conf/spin.conf"

add_spin_to_project() {
  read -p "Do you want to add Spin to your project? (Y/n)" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    project_dir="$(pwd)/$2"
    case "$1" in
      "php")
        docker run --rm -v $project_dir:/var/www/html -e "S6_LOGGING=1" $(get_latest_image php) composer --working-dir=/var/www/html/ require serversideup/spin --dev
        ;;
      "node")
        if [[ -f "$project_dir/package-lock.json" && -f "$project_dir/package.json" ]]; then
            echo "🧐 I detected a package-lock.json file, so I'll use npm."
            docker run --rm -v $project_dir:/usr/src/app -w /usr/src/app $(get_latest_image node) npm install @serversideup/spin --save-dev
        elif [[ -f "$project_dir/pnpm-lock.yaml" ]]; then
            echo "🧐 I detected a pnpm-lock.yaml file, so I'll use pnpm."
            docker run --rm -v $project_dir:/usr/src/app -w /usr/src/app $(get_latest_image node) pnpm add -D @serversideup/spin
        elif [[ -f "$project_dir/yarn.lock" ]]; then
            echo "🧐 I detected a yarn.lock file, so I'll use yarn."
            docker run --rm -v $project_dir:/usr/src/app -w /usr/src/app $(get_latest_image node) yarn add @serversideup/spin --dev
        elif [[ -f "$project_dir/Bunfile" || -f "$project_dir/Bunfile.lock" ]]; then
            echo "🧐 I detected a Bunfile or Bunfile.lock file, so I'll use bun."
            docker run --rm -v $project_dir:/usr/src/app -w /usr/src/app $(get_latest_image node) bun add -d @serversideup/spin
        else
            echo "Unknown Node project type."
            exit 1
        fi
        ;;
      *)
        echo "Invalid argument. Supported arguments are: php, node."
        return 1
        ;;
    esac
  fi
}

check_connection_with_tool() {
    local tool="$1"
    local api_url="$2"

    case "$tool" in
        curl)
            curl --connect-timeout 2 -fsSL -H 'Accept: application/vnd.github.v3.sha' "$api_url" &>/dev/null
            ;;
        wget)
            wget -T 2 -O- --header='Accept: application/vnd.github.v3.sha' "$api_url" &>/dev/null
            ;;
        fetch)
            HTTP_ACCEPT='Accept: application/vnd.github.v3.sha' fetch -T 2 -o - "$api_url" &>/dev/null
            ;;
        *)
            echo "Invalid argument. Supported arguments are: curl, wget, fetch."
            return 1
            ;;
    esac
}

check_for_upgrade() {
  if ! is_within_interval_threshold ".spin-last-update" $AUTO_UPDATE_INTERVAL_IN_DAYS  || [ "$1" == "--force" ]; then
    if [ "$1" != "--force" ]; then
      read -p "${BOLD}${YELLOW}\[spin] 🤔 Would you like to check for updates? [Y/n]${RESET}" response
      case "$response" in
        [yY$'\n'])
          send_to_upgrade_script
          ;;
        * )
          # Do nothing if the answer is not yes.
          save_current_time_to_cache_file ".spin-last-update"
          echo "[spin] You can update manually by running \`spin update\`"
          ;;
      esac
    else
      send_to_upgrade_script
    fi
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
  if is_internet_connected; then

    if [ "$1" == "--no-pull" ]; then
      printf "${BOLD}${YELLOW}❗️ Skipping automatic docker image pull.${RESET}\n"
      shift 1
      PULL_PROCESSED_COMMANDS="$@"
      return
    fi
    $COMPOSE pull --ignore-pull-failures
    PULL_PROCESSED_COMMANDS="$@"
    save_current_time_to_cache_file ".spin-last-pull"
  else
      printf "${BOLD}${YELLOW}❗️ Skipping automatic docker image pull.${RESET}\n"
      PULL_PROCESSED_COMMANDS="$@"
  fi

  return
}

get_latest_image() {
    case "$1" in
        "php")
            echo "serversideup/php:8.2-cli"
            ;;
        "node")
            echo "node:18"
            ;;
        *)
            echo "Invalid argument. Supported arguments are: php, node."
            return 1
            ;;
    esac
}

is_within_interval_threshold() {
  local spin_cache_file="$SPIN_CACHE_DIR/$1"
  local interval="$2"

  if [ ! -f $spin_cache_file ]; then
    # If the file doesn't exist, we're not within the threshold
    return 1
  fi

  local last_update_time=$(cat $spin_cache_file)
  local threshold_time=$(current_time_minus $interval)

  (( last_update_time <= threshold_time )) && return 1 || return 0
}


is_installed_to_user() {
if [[ "$SPIN_HOME" =~ (/vendor/bin|/node_modules/.bin) ]]; then
    return 1  # Installed by a project (via composer or npm/yarn/bun)
  else
    return 0  # Assume installed to system/user
  fi
}

not_in_active_development() {
if [[ "$SPIN_HOME" =~ (\.spin) ]]; then
    return 0 # If .spin is found in SPIN_HOME, assume it's not in active development
  else
    return 1
  fi
}

is_internet_connected() {
    local repo="serversideup/spin"
    local branch="main"
    local api_url="https://api.github.com/repos/${repo}/commits/${branch}"

    # Tools to be checked in order
    local tools=("curl" "wget" "fetch")

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null && check_connection_with_tool "$tool" "$api_url"; then
            return 0
        else
          printf "${BOLD}${YELLOW}\"spin\" tried to check for updates, but we couldn't connect to Github.com. We'll try again tomorrow.${RESET} \n"
          # Take the current time and subtract just one day short of the auto update interval so we check again tomorrow
          echo $(current_time_minus $(expr $AUTO_UPDATE_INTERVAL_IN_DAYS - 1)) > $SPIN_CACHE_DIR/.spin-last-update
          return 1
        fi
    done

    # If none of the tools are available, print an error
    printf "${BOLD}${RED}Automatic updates are not available because curl, wget, or fetch are not installed.${RESET}\n"
    return 1
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

save_current_time_to_cache_file() {
  mkdir -p $SPIN_CACHE_DIR
  date +"%s" > $SPIN_CACHE_DIR/$2
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