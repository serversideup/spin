#!/usr/bin/env bash

check_connection_with_cmd() {
    local cmd="$1"
    local api_url="$2"

    case "$cmd" in
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
  if needs_update ".spin-last-update" "$AUTO_UPDATE_INTERVAL_IN_DAYS"  || [ "$1" == "--force" ]; then
    if [ "$1" != "--force" ]; then
      read -n 1 -r -p "${BOLD}${YELLOW}[spin] 🤔 Would you like to check for updates? [Y/n]${RESET} " response
      case "$response" in
        [yY$'\n'])
          send_to_upgrade_script
          ;;
        * )
          echo
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

check_if_docker_is_running(){
  if ! docker info > /dev/null 2>&1; then
    printf "${BOLD}${RED}❌ Docker is not running.${RESET} "
    printf "You need to start Docker Desktop or install Docker before using \"spin\".\n"
    exit 1
  fi
}

check_if_compose_files_exist() {
    local compose_files=$1
    local IFS=:
    local -a files

    read -ra files <<< "$compose_files"

    # Flags to track if default and env-specific files are missing
    local default_missing=false
    local env_missing_file=""

    # Iterate through each file and check for its existence
    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            if [[ "$file" == "docker-compose.yml" ]]; then
                default_missing=true
            else
                env_missing_file="$file"
            fi
        fi
    done

    # Handle the missing file scenarios
    if $default_missing && [[ -n "$env_missing_file" ]]; then
        printf '%s\n' "${BOLD}${YELLOW}[spin] 🛑 Missing files: docker-compose.yml and $env_missing_file!${RESET}"
        echo "👉 Be sure you're running 'spin' from your project root."
        exit 1
    elif [[ -n "$env_missing_file" ]]; then
        printf '%s\n' "${BOLD}${YELLOW}[spin] ⚠️ $env_missing_file is missing, but a docker-compose.yml file exists.${RESET}"
        printf "Do you want to proceed using just docker-compose.yml? (y/n) "
        # Read a single character as input
        read -n 1 decision
        echo  # Move to a new line for clarity
        if [[ "$decision" != "y" && "$decision" != "Y" ]]; then
            echo "🛑 $env_missing_file doesn't exist. Set a different environment with \"SPIN_ENV\"."
            exit 1
        else
            export COMPOSE_FILE="docker-compose.yml"
        fi
    elif $default_missing; then
        printf '%s\n' "${BOLD}${YELLOW}[spin] 🛑 Missing file: docker-compose.yml!${RESET}"
        echo "👉 Be sure you're running 'spin' from your project root."
        exit 1
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
    Darwin*)    DATE_THRESHOLD=$(date -v -"${days_to_subtract}d" +%s);;
    *)          echo "We're unsure how to calculate a date on your operating system." && exit 2
  esac

  echo $DATE_THRESHOLD

}

display_repository_metadata() {
  local repo="$1"
  local branch="$2"
  local meta_url="https://raw.githubusercontent.com/$repo/$branch/meta.yml"
  local meta_content="" title="" description="" repository="" issues="" authors=""

  # Check if the URL is reachable
  if curl --output /dev/null --silent --head --fail "$meta_url"; then
    # Download the file content into a variable using curl
    local meta_content=$(curl -s "$meta_url")

    local title=$(echo "$meta_content" | grep '^title:' | awk -F': ' '{print $2}')
    local description=$(echo "$meta_content" | grep '^description:' | awk -F': ' '{print $2}')
    local repository=$(echo "$meta_content" | grep '^repository:' | awk -F': ' '{print $2}')
    local issues=$(echo "$meta_content" | grep '^issues:' | awk -F': ' '{print $2}')
    local authors=$(echo "$meta_content" | awk '/^authors:/,/^$/ { if (!/^authors:/ && !/^$/ && $1 == "-") { gsub(/^  - /, "", $0); printf("%s, ", $0) } }' | sed 's/, $//')

    echo -e "${BOLD}${GREEN}Repository Metadata:${RESET}"
    echo -e "${BOLD}Title:${RESET} $title"
    echo -e "${BOLD}Description:${RESET} $description"
    echo -e "${BOLD}Authors:${RESET} $authors"
    echo -e "${BOLD}Repository URL:${RESET} $repository"
    echo -e "${BOLD}Issues Tracker URL:${RESET} $issues"
    echo ""
  else
    echo "${BOLD}${RED}Metadata file not available for https://github.com/$repo"
    echo
    echo "Please check the repository for more information.${RESET}"
  fi
}

docker_pull_check() {
  local pull=0
  local output=$(printf '%s\n' "${BOLD}${BLUE}[spin] ⚡️ Skipping docker image pull because it ran earlier.${RESET}")

  for arg in "$@"; do
    case "$arg" in
      --skip-pull)
        pull=1
        output=$(printf '%s\n' "${BOLD}${YELLOW}[spin] ❗️ Skipping automatic docker image pull because of '--skip-pull' was set.${RESET}")
        ;;
      --force-pull)
        pull=2
        output=$(printf '%s\n' "${BOLD}${YELLOW}[spin] ❗️ Forcing a pull of Docker Compose images because '--force-pull' was set.${RESET}")
        ;;
    esac
  done
  
  if [ "$pull" != "1" ] && (needs_update ".spin-last-pull" "$AUTO_PULL_INTERVAL_IN_DAYS" || [ "$pull" == "2" ]); then
    $COMPOSE_CMD pull
    update_last_pull_timestamp
  else
    echo "$output"
  fi
}

export_compose_file_variable(){
  # Convert the SPIN_ENV variable into an array of environments
  IFS=',' read -ra ENV_ARRAY <<< "$SPIN_ENV"

  # Initialize the COMPOSE_FILE variable
  COMPOSE_FILE="docker-compose.yml"

  # Loop over each environment and append the corresponding compose file
  for env in "${ENV_ARRAY[@]}"; do
    COMPOSE_FILE="$COMPOSE_FILE:docker-compose.$env.yml"
  done

  # Export the COMPOSE_FILE variable
  export COMPOSE_FILE

  # Check if 'set -x' is enabled
  if [[ $- == *x* ]]; then
      # If 'set -x' is enabled, echo the COMPOSE_FILE variable
      echo "SPIN_ENV: $SPIN_ENV"
      echo "COMPOSE_FILE: $COMPOSE_FILE"
  fi
}

filter_out_spin_arguments() {
    non_docker_args=(
        "--skip-pull"
        "--force-pull"
    )

    # Declare an array to hold the filtered arguments
    local filtered_args=()

    # Loop through all passed arguments
    for arg in "$@"; do
        local is_non_docker_arg=false
        for non_docker_arg in "${non_docker_args[@]}"; do
            if [[ "$arg" == "$non_docker_arg" ]]; then
                is_non_docker_arg=true
                break
            fi
        done

        if ! $is_non_docker_arg; then
            filtered_args+=("$arg")
        fi
    done

    # Return the filtered arguments as an array
    echo "${filtered_args[@]}"
}

get_github_release() {
  release_type="$1"
  local release=""
  local repo="$2"

  if [[ $release_type == "stable" ]]; then
    release=$(curl --silent "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  else
    release=$(curl --silent "https://api.github.com/repos/$repo/releases/" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)
  fi
  echo "$release"
}

get_file_from_github_release() {
  local repo="$1"
  local release_type="$2"
  local source_file="$3"
  local destination_file="$4"
  local trimmed_destination_file=${destination_file#*/}

  if [[ -f "$destination_file" ]]; then
          echo "👉 \"$trimmed_destination_file\" already exists. Skipping..."
          return 0
  fi

  curl --silent --location --output "$destination_file" "https://raw.githubusercontent.com/$repo/$(get_github_release "$release_type" "$repo")/$source_file"
  echo "✅ \"$trimmed_destination_file\" has been created."
}

installation_type() {
  if [[ "$SPIN_HOME" =~ (/vendor/bin|/node_modules/.bin) ]]; then
    echo "project"
  elif [[ "$SPIN_HOME" =~ (\.spin) ]]; then
    echo "user"
  else
    echo "development"
  fi
}

is_encrypted_with_ansible_vault() {
  local file="$1"

  if [ ! -f "$file" ]; then
    return 1
  fi

  if head -n 1 "$file" | grep -q '^\$ANSIBLE_VAULT;1\.1;AES256'; then
    return 0
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
        if command -v "$tool" &>/dev/null && check_connection_with_cmd "$tool" "$api_url"; then
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

last_pull_timestamp() {
    local project_dir="$(pwd)"
    local cache_file="$SPIN_CACHE_DIR/.spin-last-pull"
    
    # Escape special characters in the directory path to safely use it in regular expressions
    # sed is used to add a backslash before characters that have special meaning in regex
    local escaped_project_dir=$(printf '%s' "$project_dir" | sed 's/[][\.|$(){}?+*^]/\\&/g')

    grep "^$escaped_project_dir " "$cache_file" | awk '{print $2}'
}

needs_update() {
  # Checks if an update is needed based on the last update time and a given interval.
  # Parameters:
  #   1: Name of the cache file (relative to $SPIN_CACHE_DIR)
  #   2: Interval in days to check against

  local cache_file="$SPIN_CACHE_DIR/$1"
  local interval="$2"
  local last_update_time

  # Check if the cache file exists
  if [ ! -f "$cache_file" ]; then
    printf '%s\n' "${BOLD}${YELLOW}[spin] 🤔 We can't tell when you last checked for updates, so we'll try updating now...${RESET}"
    return 0
  fi

  # Determine the time of the last update
  case "$1" in
    ".spin-last-pull")
        last_update_time=$(last_pull_timestamp)
        ;;
    *)
        last_update_time=$(cat "$cache_file")
        ;;
  esac

  # Calculate the threshold time for update
  local threshold_time=$(current_time_minus "$interval")
  
  if (( threshold_time <= last_update_time )); then
    return 1
  else
    return 0
  fi
}

print_version() {

  # Use the local Git repo to show our version
  printf "${BOLD}${YELLOW}Spin Version:${RESET} \n"
  printf "$(git -C $SPIN_HOME describe --tags) "

  if [[ "$(installation_type)" == "user" ]]; then
    source $SPIN_CONFIG_FILE_LOCATION
    printf "[$TRACK] "
    printf "(User Installed)\n"
  elif [[ "$(installation_type)" == "project" ]]; then
    printf "(Project Installed)\n"
  else
    printf "(Development)\n"
  fi
}

check_if_template_exists_and_has_access(){
  local repo="$1"
  local branch="$2"

  if [ -z "$branch" ]; then
    branch=$(github_default_branch "$repo")
  fi
  local url="https://github.com/$repo/archive/refs/heads/$branch.tar.gz"

  if curl --head --silent --fail $url &> /dev/null &> /dev/null; then
    return 0
  else
    echo "${BOLD}${RED}🛑 Repository does not exist or you do not have access to it.${RESET}"
    echo ""
    echo "${BOLD}${YELLOW}👇Try running this yourself to debug access:${RESET}"
    echo "curl $url"
    echo ""
    exit 1
  fi
}

run_ansible (){
  ansible_collections_path="./.infrastructure/conf/spin/collections"
  
  # Mount the SSH Agent for macOS systems
  if [[ "$(uname -s)" == "Darwin" ]]; then
      local additional_docker_configs="-v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock"
  fi

  docker run --rm -it \
    -v "$(pwd):/ansible" \
    -v ~/.ssh/:/root/.ssh/ \
    -v $ansible_collections_path:/root/.ansible/collections \
    --platform linux/amd64 \
    $additional_docker_configs \
    $SPIN_ANSIBLE_IMAGE \
    "$@"
}

save_current_time_to_cache_file() {
  mkdir -p $SPIN_CACHE_DIR
  date +"%s" > $SPIN_CACHE_DIR/$1
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

update_last_pull_timestamp() {
    local file="$SPIN_CACHE_DIR/.spin-last-pull"
    local project_dir="$(pwd)"
    local current_time="$(date +"%s")"

    # Ensure the file exists
    touch "$file"

    # Comments explaining the awk script:
    # If the first field of the line ($1) matches the current project directory:
    #   - Print the project directory and the new timestamp.
    #   - Mark that we've found a match with the variable 'found'.
    #   - Skip further processing for this line and move to the next line.
    # For all other lines:
    #   - Print them as they are.
    # After processing all lines:
    #   - If we did not find a match for the project directory in the file:
    #       - Add a new entry with the project directory and current timestamp.
    awk -v dir="$project_dir" -v time="$current_time" '
        $1 == dir { 
            print dir, time; 
            found=1; 
            next 
        }

        { print }
        
        END { 
            if(!found) 
                print dir, time 
        }
    ' "$file" > "$file.tmp" # Redirect the output of the awk command to a temporary file

    # Replace the original .spin-last-pull file with the updated temporary file
    mv "$file.tmp" "$file"
}