#!/usr/bin/env bash

add_user_todo_item() {
    if [ -z "$SPIN_USER_TODOS" ]; then
        SPIN_USER_TODOS="$1"
    else
        SPIN_USER_TODOS="$SPIN_USER_TODOS"$'\n'"$1"
    fi
}

base64_encode() {
    local input="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        base64 -i "$input"
    else
        base64 "$input"
    fi
}

base64_decode() {
    local input="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        base64 -D "$input"
    else
        base64 -d "$input"
    fi
}

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

cleanup_temp_repo_location() {
  rm -rf "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR"
}

copy_template_files() {
  local src_dir="$1"
  local dest_dir="$2"
  
  while IFS= read -r file; do
    target_file="$dest_dir/${file#"$src_dir/"}"
    # Compute the relative path for the echo statements
    relative_target_file="${target_file#"$dest_dir"/}"

    if [[ -f "$target_file" ]]; then
        trap show_existing_files_warning EXIT
        echo "👉 ${MAGENTA}\"$relative_target_file\" already exists. Skipping...${RESET}"
    else
        mkdir -p "$(dirname "$target_file")"
        if cp "$file" "$target_file"; then
            echo "✅ \"$relative_target_file\" has been created."
        else
            echo "${BOLD}${RED}❌ Error copying \"$file\" to \"$relative_target_file\".${RESET}"
        fi
    fi
  done < <(find "$src_dir" -type f -print)
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

  echo "$DATE_THRESHOLD"

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

download_spin_template_repository() {
  local branch=''
  local template_type=''
  local args_without_options=()
  local local_src=false
  SPIN_INSTALL_DEPENDENCIES=${SPIN_INSTALL_DEPENDENCIES:-true}
  framework_args=()
 
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -b|--branch)
        branch="$2"
        shift 2
        ;;
      -l|--local)
        SPIN_TEMPLATE_TEMPORARY_SRC_DIR="$2"
        local_src=true
        shift 2
        ;;
      -s|--skip-dependency-install)
        SPIN_INSTALL_DEPENDENCIES=false
        shift
        ;;
      -*)
        echo "${BOLD}${RED}🛑 Unsupported flag ${1}.${RESET}"
        exit 1
        ;;
      *)
        args_without_options+=("$1")
        shift
        ;;
    esac
  done

  export SPIN_INSTALL_DEPENDENCIES

  if [[ $local_src == false ]]; then
    # First positional argument should be the template or template repository
    if [ ! -z "${args_without_options[0]}" ]; then
      template="${args_without_options[0]}"
      unset "args_without_options[0]"
    else
      echo "${BOLD}${RED}Error: No template specified for remote repository.${RESET}"
      exit 1
    fi
  
    # Determine the type of template
    case "$template" in
      laravel)
        template_type=official
        TEMPLATE_REPOSITORY="serversideup/spin-template-laravel-basic"
        branch="${branch:-"main"}"
        ;;
      laravel-pro)
        template_type=official
        TEMPLATE_REPOSITORY="serversideup/spin-template-laravel-pro"
        branch="${branch:-"main"}"
        ;;
      nuxt)
        template_type=official
        TEMPLATE_REPOSITORY="serversideup/spin-template-nuxt"
        ;;
      *)
        template_type=external
        TEMPLATE_REPOSITORY="$template"
        ;;
    esac
    
    export TEMPLATE_REPOSITORY
  fi

  # Remaining positional arguments are considered framework arguments
  framework_args=("${args_without_options[@]}")
  export framework_args

  # If the user specified a local template, we don't need to download anything
  if [[ "$template_type" == "local" ]]; then
    echo "${BOLD}${GREEN}✅ Using local template: $SPIN_TEMPLATE_TEMPORARY_SRC_DIR${RESET}"
    return 0
  fi

  if [[ $local_src == false ]]; then
    # Get the default branch if not specified
    if [[ -z "$branch" ]]; then
      # If branch is not specified, get the default branch
      branch=$(github_default_branch "$TEMPLATE_REPOSITORY")
      
      # Check if we successfully got the default branch
      if [[ -z "$branch" ]]; then
        echo "${BOLD}${RED}Error: Couldn't determine the default branch for $TEMPLATE_REPOSITORY.${RESET}"
        exit 1
      fi
    fi

    # Create a temporary directory for the template
    trap cleanup_temp_repo_location EXIT
    SPIN_TEMPLATE_TEMPORARY_SRC_DIR=$(mktemp -d)
    local api_url="https://api.github.com/repos/$TEMPLATE_REPOSITORY"

    # Third-party repository warning and confirmation
    if [[ "$template_type" != "official" ]]; then
      echo "${BOLD}${YELLOW}⚠️ You're downloading content from a third party repository.${RESET}"

      if ! curl --output /dev/null --silent --head --fail "$api_url"; then
        echo "${BOLD}${YELLOW}🚨 Metadata file not available for https://github.com/$TEMPLATE_REPOSITORY${RESET}"
        echo "Please check the repository for more information."
        echo 
      else
        display_repository_metadata "$TEMPLATE_REPOSITORY" "$branch"
      fi

      echo "${BOLD}${BLUE}Make sure you trust the source of the repository before continuing.${RESET}"
      echo "Do you wish to continue? (y/n)"
      read -r -n 1 -p ""
      echo  # Move to a new line

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BOLD}${RED}❌ Operation cancelled.${RESET}"
        exit 1
      fi
    fi

    echo "${BOLD}${YELLOW}🔄 Downloading template...${RESET}"
    
    local https_url="https://github.com/$TEMPLATE_REPOSITORY.git"
    local ssh_url="git@github.com:$TEMPLATE_REPOSITORY.git"

    # Function to show progress
    show_progress() {
      local pid=$1
      local delay=0.5
      local spinstr='|/-\'
      while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
      done
      printf "    \b\b\b\b"
    }

    # Try HTTPS first if the API was accessible
    if curl --output /dev/null --silent --head --fail "$api_url"; then
      (
        git clone -q -b "$branch" "$https_url" "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR"
      ) &

      show_progress $!

      if [ -d "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/.git" ]; then
        echo "${BOLD}${GREEN}✅ Template downloaded successfully via HTTPS.${RESET}"
        return 0
      fi
    fi

    # If HTTPS failed or API wasn't accessible, try SSH  
    (
      git clone -q -b "$branch" "$ssh_url" "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR"
    ) &

    show_progress $!

    # Check if SSH clone was successful
    if [ -d "$SPIN_TEMPLATE_TEMPORARY_SRC_DIR/.git" ]; then
      echo "${BOLD}${GREEN}✅ Template downloaded successfully via SSH.${RESET}"
    else
      echo "${BOLD}${RED}❌ Failed to download template. Please check your internet connection and GitHub access.${RESET}"
      exit 1
    fi
  fi

  # Export so other functions can use it
  export SPIN_TEMPLATE_TEMPORARY_SRC_DIR
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

get_ansible_variable(){
  local variable_name="$1"
  local raw_output=''
  local clean_output=''
  shift

  if [[ -z "$variable_name" ]]; then
    echo "${BOLD}${RED}❌ No variable name specified.${RESET}" >&2
    return 1
  fi

  # Temporarily disable trace output if it's enabled
  local trace_enabled=0
  if [[ $- == *x* ]]; then
    set +x
    trace_enabled=1
  fi

  # Get vault args if needed
  local vault_args=()
  IFS=' ' read -r -a vault_args < <(set_ansible_vault_args)

  echo "Gathering environment information..." >&2

  # Run ansible command directly with docker
  raw_output=$(docker run --rm -i \
    -e "PUID=${SPIN_USER_ID}" \
    -e "PGID=${SPIN_GROUP_ID}" \
    -e "RUN_AS_USER=${SPIN_RUN_AS_USER}" \
    -e "ANSIBLE_STDOUT_CALLBACK=minimal" \
    -e "ANSIBLE_DISPLAY_SKIPPED_HOSTS=false" \
    -e "ANSIBLE_DISPLAY_OK_HOSTS=false" \
    -v "$SPIN_ANSIBLE_COLLECTIONS_PATH:/etc/ansible/collections" \
    -v "$(pwd):/ansible" \
    -w /ansible \
    "$SPIN_ANSIBLE_IMAGE" \
    ansible-playbook \
    serversideup.spin.get_variable \
    --inventory "$SPIN_INVENTORY_FILE" \
    "${vault_args[@]}" \
    --extra-vars @./.spin.yml \
    --extra-vars "variable_name=$variable_name" 2>&1) || {
      echo "${BOLD}${RED}❌ Failed to get ansible variable: $variable_name${RESET}" >&2
      echo "${BOLD}${RED}Error: $raw_output${RESET}" >&2
      # Restore trace output if it was enabled
      if [[ $trace_enabled -eq 1 ]]; then set -x; fi
      return 1
    }

  # Extract just the value from the msg field
  clean_output=$(echo "$raw_output" | grep -o '"msg": .*' | sed 's/"msg": //;s/^"//;s/"$//')

  # Restore trace output if it was enabled
  if [[ $trace_enabled -eq 1 ]]; then set -x; fi

  # Return the cleaned output
  echo "$clean_output"
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
  local source_type="release"  # Default to release downloads

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -r|--repo)
        local repo="$2"
        shift 2
        ;;
      -t|--release-type)
        local release_type="$2"
        shift 2
        ;;
      -b|--branch)
        local branch="$2"
        source_type="branch"
        shift 2
        ;;
      -s|--src)
        local source_file="$2"
        shift 2
        ;;
      -d|--dest)
        local destination_file="$2"
        shift 2
        ;;
      *)
        echo "${BOLD}${RED}🛑 Unsupported flag ${1}.${RESET}"
        exit 1
        ;;
    esac
  done

  destination_filename=$(basename "$destination_file")

  if [[ -f "$destination_file" ]]; then
    trap show_existing_files_warning EXIT
    echo "👉 ${MAGENTA}\"$destination_filename\" already exists. Skipping...${RESET}"
    return 0
  fi

  # Construct the URL based on source type
  local download_url
  if [[ "$source_type" == "branch" ]]; then
    download_url="https://raw.githubusercontent.com/$repo/$branch/$source_file"
  else
    download_url="https://raw.githubusercontent.com/$repo/$(get_github_release "$release_type" "$repo")/$source_file"
  fi

  curl --silent --location --output "$destination_file" "$download_url"
  echo "✅ \"$destination_filename\" has been created."
}

get_md5_hash() {
  local file="$1"
  local md5_hash=""

  if [[ -f "$file" ]]; then
    if command -v md5 > /dev/null 2>&1; then
        # MacOS typically uses 'md5'
        md5_hash=$(md5 -q "$file")
    elif command -v md5sum > /dev/null 2>&1; then
        # Linux typically uses 'md5sum'
        md5_hash=$(md5sum "$file" | awk '{ print $1 }')
    else
        echo "MD5 tool not available."
        return 1
    fi
  else
    echo "File not found."
    return 1
  fi

  echo "$md5_hash" 
}

github_default_branch() {
  local repo="$1"
  local branch=""
  
  branch=$(curl --silent "https://api.github.com/repos/$repo" | grep '"default_branch":' | sed -E 's/.*"([^"]+)".*/\1/')

  echo "$branch"
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
    local cache_file="$SPIN_CACHE_DIR/.spin-last-pull"
    local escaped_project_dir=""
    
    # Escape special characters in the directory path to safely use it in regular expressions
    # sed is used to add a backslash before characters that have special meaning in regex
    
    escaped_project_dir=$(printf '%s' "$(pwd)" | sed 's/[][\.|$(){}?+*^]/\\&/g')

    grep "^$escaped_project_dir " "$cache_file" | awk '{print $2}'
}

line_in_file() {
    local action="ensure"
    local files=()
    local args=()
    local ignore_missing=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --file)
                files+=("$2")
                shift 2
                ;;
            --action)
                action="$2"
                shift 2
                ;;
            --ignore-missing)
                ignore_missing=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Error: No file specified" >&2
        return 1
    fi

    if [[ ${#args[@]} -eq 0 && "$action" != "search" ]]; then
        echo "Error: No content specified" >&2
        return 1
    fi

    # Process each file
    for file in "${files[@]}"; do
        # Create the file if it doesn't exist
        if [[ ! -f "$file" ]]; then
            touch "$file"
        fi

        case $action in
            ensure)
                for line in "${args[@]}"; do
                    if ! grep -qF -- "$line" "$file"; then
                        echo "$line" >> "$file"
                    fi
                done
                ;;
            replace)
                if [[ ${#args[@]} -ne 2 ]]; then
                    echo "Error: Replace action requires exactly two arguments (search and replace)" >&2
                    return 1
                fi
                if grep -q -- "^${args[0]}" "$file"; then
                    # Escape forward slashes in the replacement string
                    local escaped_replace=$(echo "${args[1]}" | sed 's/\//\\\//g')
                    # Match lines that start with the search term, followed by anything
                    sed_inplace "s/^${args[0]}.*$/${escaped_replace}/" "$file"
                else
                    # Check if the exact replacement line already exists
                    if ! grep -qF -- "${args[1]}" "$file"; then
                        echo "${args[1]}" >> "$file"
                    fi
                fi
                ;;
            after)
                if [[ ${#args[@]} -ne 2 ]]; then
                    echo "Error: After action requires exactly two arguments (search and insert)" >&2
                    return 1
                fi
                if grep -qF -- "${args[0]}" "$file"; then
                    # Use sed to insert the new line after the matching line
                    sed_inplace -e "/${args[0]}/!b" -e "a\\
${args[1]}" "$file"
                else
                    echo "${args[0]}" >> "$file"
                    echo "${args[1]}" >> "$file"
                fi
                ;;
            exact)
                if [[ ${#args[@]} -ne 2 ]]; then
                    echo "Error: Exact action requires exactly two arguments (search and replace)" >&2
                    return 1
                fi
                if grep -qF -- "${args[0]}" "$file"; then
                    sed_inplace "s/${args[0]}/${args[1]}/g" "$file"
                else
                    if [[ "$ignore_missing" == true ]]; then
                        return 0
                    else
                        echo "Error: Exact text '${args[0]}' not found in $file" >&2
                        return 1
                    fi
                fi
                ;;
            search)
                if grep -qF -- "${args[0]}" "$file"; then
                    return 0  # True, content found
                else
                    return 1  # False, content not found
                fi
                ;;
            delete)
                if [[ ${#args[@]} -ne 1 ]]; then
                    echo "Error: Delete action requires exactly one argument (text to delete)" >&2
                    return 1
                fi
                if grep -qF -- "${args[0]}" "$file"; then
                    # Use sed to delete lines containing the specified text
                    sed_inplace "/${args[0]}/d" "$file"
                else
                    echo "Warning: Text '${args[0]}' not found in $file" >&2
                fi
                ;;
            *)
                echo "Error: Invalid action '$action'" >&2
                return 1
                ;;
        esac
    done
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
  
  if (( last_update_time >= threshold_time )); then
    return 1  # No update needed - last update is newer than threshold
  else
    return 0  # Update needed - last update is older than threshold
  fi
}

prepare_ansible_run() {
    # Return values will be stored in these global variables
    SPIN_ANSIBLE_ARGS=()
    SPIN_UNPROCESSED_ARGS=()
    SPIN_REMOTE_USER="$USER"
    SPIN_FORCE_INSTALL_GALAXY_DEPS=${SPIN_FORCE_INSTALL_GALAXY_DEPS:-false}
    SPIN_INVENTORY_FILE="${SPIN_INVENTORY_FILE:-"/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh"}"
    SPIN_ANSIBLE_COLLECTIONS_PATH="$SPIN_CACHE_DIR/collections"
    
    # Process arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --host|-h)
                SPIN_ANSIBLE_ARGS+=("--extra-vars" "target=$2")
                shift 2
                ;;
            --user|-u)
                SPIN_REMOTE_USER="$2"
                shift 2
                ;;
            --port|-p)
                SPIN_ANSIBLE_ARGS+=("--extra-vars" "ansible_port=$2")
                shift 2
                ;;
            --upgrade|-U)
                SPIN_FORCE_INSTALL_GALAXY_DEPS=true
                shift
                ;;
            *)
                SPIN_UNPROCESSED_ARGS+=("$1")
                shift
                ;;
        esac
    done

    if [[ -f ".spin-inventory.ini" ]]; then
        SPIN_INVENTORY_FILE="/ansible/.spin-inventory.ini"
    fi

    # Create the collections directory if it doesn't exist
    if [[ ! -d "$SPIN_ANSIBLE_COLLECTIONS_PATH" ]]; then
        mkdir -p "$SPIN_ANSIBLE_COLLECTIONS_PATH"
    fi

    # Install Ansible Galaxy dependencies if the flag is set
    if [[ $(needs_update ".spin-ansible-collection-pull" "1") || "$SPIN_FORCE_INSTALL_GALAXY_DEPS" == true ]]; then
      echo "Installing Ansible Galaxy dependencies..."
      docker run --rm -it \
        -e "PUID=${SPIN_USER_ID}" \
        -e "PGID=${SPIN_GROUP_ID}" \
        -e "RUN_AS_USER=${SPIN_RUN_AS_USER}" \
        -v "$SPIN_ANSIBLE_COLLECTIONS_PATH:/etc/ansible/collections" \
        "$SPIN_ANSIBLE_IMAGE" \
        ansible-galaxy collection install "${SPIN_ANSIBLE_COLLECTION_NAME}" --force
      save_current_time_to_cache_file ".spin-ansible-collection-pull"
    fi

    # Append vault args to additional ansible args
    IFS=' ' read -r -a vault_args < <(set_ansible_vault_args)
    SPIN_ANSIBLE_ARGS+=("${vault_args[@]}")
}

print_version() {
  # Use the local Git repo to show our version
  printf "${BOLD}${YELLOW}Spin Version:${RESET} \n"

  if [[ "$(installation_type)" == "user" ]]; then
    printf "$(git -C $SPIN_HOME describe --tags) "
    source $SPIN_CONFIG_FILE_LOCATION
    printf "[$TRACK] "
    printf "(User Installed)\n"
  elif [[ "$(installation_type)" == "project" ]]; then
    printf "(Project Installed)\n"
    printf "Check local package.lock or composer.lock for version details\n"
  else
    printf "$(git -C $SPIN_HOME describe --tags) "
    printf "(Development)\n"
  fi
}

prompt_and_update_file() {
    local files=()
    local search_default=""
    local title=""
    local details=""
    local success_message=""
    local prompt="Enter your response"
    local output_only=false
    local validate=""
    local clear_screen=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --file)
                files+=("$2")
                shift 2
                ;;
            --search-default)
                search_default="$2"
                shift 2
                ;;
            --title)
                title="$2"
                shift 2
                ;;
            --details)
                details="$2"
                shift 2
                ;;
            --prompt)
                prompt="$2"
                shift 2
                ;;
            --success-msg)
                success_message="$2"
                shift 2
                ;;
            --output-only)
                output_only=true
                shift
                ;;
            --validate)
                validate="$2"
                shift 2
                ;;
            --clear-screen)
                clear_screen=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$title" ]]; then
        echo -e "${BOLD}${RED}Error: Missing required parameter 'title' for prompt_and_update_file function.${RESET}" >&2
        return 1
    fi
    if [[ "$output_only" == false ]]; then
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "Error: No files specified for update. Please use the --file option to specify at least one file or set --output-only to true." >&2
            return 1
        fi
        if [[ -z "$search_default" ]]; then
            echo -e "${BOLD}${RED}Error: Missing required parameter 'search-default' for file update mode.${RESET}" >&2
            return 1
        fi
    fi

    if [[ "$clear_screen" == true ]]; then
        clear >&2
    fi

    echo -e "${BOLD}${BLUE}$title${RESET}" >&2
    if [[ -n "$details" ]]; then
        echo -e "$details" >&2
    fi

    local value_to_use=""
    while true; do
        if [[ -n "$search_default" ]]; then
            read -p "$(echo -e "${BOLD}${YELLOW}$prompt [$search_default]:${RESET} ")" user_response >&2
            value_to_use="${user_response:-$search_default}"
        else
            read -p "$(echo -e "${BOLD}${YELLOW}$prompt:${RESET} ")" value_to_use >&2
        fi

        # Validate input if --validate flag is set
        if [[ -n "$validate" ]]; then
            case "$validate" in
                email)
                    if [[ "$value_to_use" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
                        break
                    else
                        echo -e "${BOLD}${RED}Invalid email address. Please try again.${RESET}" >&2
                        continue
                    fi
                    ;;
                # Add more validation options here in the future
                *)
                    echo "Unknown validation type: $validate" >&2
                    return 1
                    ;;
            esac
        else
            break
        fi
    done

    if [[ "$output_only" == true ]]; then
        # Just output the value to stdout
        echo "$value_to_use"
    else
        # Update each specified file
        for file in "${files[@]}"; do
            line_in_file --action exact --file "$file" "$search_default" "$value_to_use"
        done

        if [[ -n "$success_message" ]]; then
            echo -e "✅ $success_message" >&2
        fi
    fi
}

prompt_to_encrypt_files(){
  local files_passed=()
  local files_to_encrypt=()
  local absolute_path=''

  # Process arguments
  while [[ $# -gt 0 ]]; do
      case "$1" in
        --file|-f)
            if [[ -n "$2" && "$2" != -* ]]; then
                files_passed+=("$2")
                shift 2
            else
                echo "${BOLD}${RED}❌Error: '-f' option requires a file as argument.${RESET}"
                exit 1
            fi
            ;;
        --path|-p)
            absolute_path=$(realpath "$2")
            shift 2
            ;;
        *)
          echo "${BOLD}${RED}🛑 Unsupported flag ${1}.${RESET}"
          exit 1
          ;;
      esac
    done

    for file in "${files_passed[@]}"; do
        if ! is_encrypted_with_ansible_vault "$absolute_path/$file"; then
            files_to_encrypt+=("$file")
        fi
    done

    if [ ${#files_to_encrypt[@]} -ne 0 ]; then
        while true; do
            echo "${BOLD}${YELLOW}⚠️ Your Spin configurations are not encrypted. We HIGHLY recommend encrypting it. Would you like to encrypt it now?${RESET}"
            echo -n "Enter \"y\" or \"n\": "
            read -r -n 1 encrypt_response
            echo # move to a new line

            if [[ $encrypt_response =~ ^[Yy]$ ]]; then
                echo "${BOLD}${BLUE}⚡️ Running Ansible Vault to encrypt Spin configurations...${RESET}"
                echo "${BOLD}${YELLOW}⚠️ NOTE: This password will be required anytime someone needs to change these files.${RESET}"
                echo "${BOLD}${YELLOW}We recommend using a RANDOM PASSWORD.${RESET}"

                # Encrypt with Ansible Vault
                run_ansible --mount-path "$absolute_path" ansible-vault encrypt "${files_to_encrypt[@]}"

                # Ensure the files are owned by the current user
                run_ansible --mount-path "$absolute_path" chown "${SPIN_USER_ID}:${SPIN_GROUP_ID}" "${files_to_encrypt[@]}"

                echo "ℹ️ You can save this password in a \".vault-password\" file in the root of your project to avoid this prompt."
                break
            elif [[ $encrypt_response =~ ^[Nn]$ ]]; then
                echo "${BOLD}${BLUE}👋 Ok, we won't encrypt these files.${RESET} You can always encrypt it later by running \"spin vault encrypt\"."
                break
            else
                echo "${BOLD}${RED}❌ Invalid response. Please respond with \"y\" or \"n\".${RESET}"
                # The loop will continue, prompting the user again
            fi
        done
    fi
}

run_ansible() {
  local additional_docker_args=()
  local ansible_args=()
  local args_without_options=()
  local allow_ssh=false
  local minimal_output=false
  local set_env=false
  local debug=${SPIN_DEBUG:-false}
  SPIN_FORCE_INSTALL_GALAXY_DEPS=${SPIN_FORCE_INSTALL_GALAXY_DEPS:-false}
  # List of environment variables that can be forwarded to Ansible container
  local env_vars_to_forward=(
    "HCLOUD_TOKEN"
    "DO_API_TOKEN"
    "VULTR_API_KEY"
  )

  # Create the known_hosts file if it doesn't exist
  if [[ ! -f "$HOME/.ssh/known_hosts" ]]; then
    touch "$HOME/.ssh/known_hosts"
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --allow-ssh)
        allow_ssh=true
        shift
        ;;
      --mount-path)
        additional_docker_args+=("-v" "${2}")
        shift 2
        ;;
      --minimal-output)
        minimal_output=true
        shift
        ;;
      --set-env)
        set_env=true
        shift
        ;;
      --container-env)
        additional_docker_args+=("-e" "$2")
        shift 2
        ;;
      *)
        ansible_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$allow_ssh" == true ]]; then
    additional_docker_args+=("-v" "$HOME/.ssh/:/ssh/:ro" "-v" "$HOME/.ssh/known_hosts:/ssh/known_hosts:rw")

    # Set remote Ansible user
    ansible_args+=("--extra-vars" "spin_remote_user=$SPIN_REMOTE_USER")

    # Check if we need to ask for sudo password
    local use_passwordless_sudo
    use_passwordless_sudo=$(get_ansible_variable "use_passwordless_sudo")
    use_passwordless_sudo=${use_passwordless_sudo:-"true"}
    if [ "$SPIN_REMOTE_USER" != "root" ] && [ "$use_passwordless_sudo" = 'false' ]; then
        ansible_args+=("--ask-become-pass")
    fi

    # Mount the SSH Agent for macOS and Linux (including WSL2) systems
    if [ -n "$SSH_AUTH_SOCK" ]; then
        case "$(uname -s)" in
            Darwin)
                # macOS
                additional_docker_args+=("-v" "/run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock" "-e" "SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock")
                ;;
            Linux)
                # Linux (including WSL2)
                additional_docker_args+=("-v" "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" "-e" "SSH_AUTH_SOCK=$SSH_AUTH_SOCK")
                ;;
        esac
    fi
  fi

  if [[ "$minimal_output" == true ]]; then
    additional_docker_args+=(
      -e "ANSIBLE_STDOUT_CALLBACK=minimal"
      -e "ANSIBLE_DISPLAY_SKIPPED_HOSTS=false"
      -e "ANSIBLE_DISPLAY_OK_HOSTS=false"
    )
  fi

  if [[ "$set_env" == true ]]; then
    additional_docker_args+=("-e" "ANSIBLE_FORCE_COLOR=1")
    
    # Forward specific environment variables if they exist
    for env_var in "${env_vars_to_forward[@]}"; do
      if [[ -n "${!env_var}" ]]; then
        # Environment variable exists in current shell
        additional_docker_args+=("-e" "${env_var}=${!env_var}")
      elif [[ -f ".env" ]] && grep -q "^${env_var}=" ".env"; then
        # Variable exists in .env file
        local env_value
        env_value=$(grep "^${env_var}=" ".env" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
        additional_docker_args+=("-e" "${env_var}=${env_value}")
      fi
    done
  fi

  # Mount collections directory if it exists
  if [[ -d "$SPIN_ANSIBLE_COLLECTIONS_PATH" ]]; then
    additional_docker_args+=("-v" "$SPIN_ANSIBLE_COLLECTIONS_PATH:/etc/ansible/collections")
  fi

  if [[ "$debug" == true ]]; then
    ansible_args+=("-vvvv")
  fi

  docker run --rm -it \
    -e "PUID=${SPIN_USER_ID}" \
    -e "PGID=${SPIN_GROUP_ID}" \
    -e "RUN_AS_USER=${SPIN_RUN_AS_USER}" \
    "${additional_docker_args[@]}" \
    "$SPIN_ANSIBLE_IMAGE" \
    "${ansible_args[@]}"
}

run_gh() {
  # Check if gh is installed locally
  if command -v gh >/dev/null 2>&1; then
    # Execute gh command locally with all arguments
    gh "$@"
    return $?  # Explicitly return the exit code from gh
  fi

  # Fall back to Docker implementation if gh is not installed
  local additional_docker_args=()
  local gh_command=("$@")
  local interactive_flag=""
  local use_tty=false
  local use_interactive=false
  local interactive_tty_commands=(
    "auth login" "auth refresh"
    "issue create" "issue edit"
    "pr create" "pr edit" "pr review"
    "repo create" "repo fork"
    "gist create" "gist edit"
  )

  # Check if there's data being piped in
  if [ ! -t 0 ]; then
    use_interactive=true  # Always use -i when receiving STDIN
  fi

  # Check if the command needs interactive TTY
  local cmd_string="${gh_command[*]}"
  for interactive_cmd in "${interactive_tty_commands[@]}"; do
    if [[ "$cmd_string" == "$interactive_cmd"* ]]; then
      use_tty=true
      use_interactive=true
      break
    fi
  done

  # Ensure the gh config directory exists
  if [[ ! -d "$HOME/.config/gh" ]]; then
    mkdir -p "$HOME/.config/gh"
  fi

  # Mount SSH if available
  if [[ -d "$HOME/.ssh" ]]; then
    additional_docker_args+=("-v" "$HOME/.ssh/:/ssh/:ro" "-v" "$HOME/.ssh/known_hosts:/ssh/known_hosts:rw")
  fi

  # Mount SSH Agent if available
  if [ -n "$SSH_AUTH_SOCK" ]; then
      case "$(uname -s)" in
        Darwin)
          # macOS
          additional_docker_args+=("-v" "/run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock" "-e" "SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock")
          ;;
        Linux)
          # Linux (including WSL2)
          additional_docker_args+=("-v" "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK" "-e" "SSH_AUTH_SOCK=$SSH_AUTH_SOCK")
          ;;
      esac
    fi
  
  # Determine interactive/TTY flags
  if [ "$use_tty" = true ] && [ "$use_interactive" = true ]; then
    interactive_flag="-it"
  elif [ "$use_tty" = true ]; then
    interactive_flag="-t"
  elif [ "$use_interactive" = true ]; then
    interactive_flag="-i"
  fi

  docker run --rm $interactive_flag \
    -e "PUID=${SPIN_USER_ID}" \
    -e "PGID=${SPIN_GROUP_ID}" \
    -e "RUN_AS_USER=${SPIN_RUN_AS_USER}" \
    -v "$(pwd):/app" \
    -v "$HOME/.config/gh:/config/gh:rw" \
    "${additional_docker_args[@]}" \
    "$SPIN_GH_CLI_IMAGE" gh "${gh_command[@]}"
}

save_current_time_to_cache_file() {
  mkdir -p "$SPIN_CACHE_DIR"
  date +"%s" > "$SPIN_CACHE_DIR/$1"
}

sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

send_to_upgrade_script () {
  if is_internet_connected; then
    source "$SPIN_HOME/tools/upgrade.sh"
  fi
}

set_ansible_vault_args() {
  local vault_args=()
  local variable_file=".spin.yml"
  local run_type="${1:-docker}"

  if [[ -f .vault-password ]]; then
    # Validate the vault password file using Docker
    if is_encrypted_with_ansible_vault "$variable_file"; then
     set +e # Disable error checking for the duration of this block
     docker run --rm -i \
        -e "PUID=${SPIN_USER_ID}" \
        -e "PGID=${SPIN_GROUP_ID}" \
        -e "RUN_AS_USER=${SPIN_RUN_AS_USER}" \
        -v "$(pwd):/ansible" \
        "$SPIN_ANSIBLE_IMAGE" \
        ansible-vault view --vault-password-file="/ansible/.vault-password" "$variable_file" > /dev/null 2>&1

      validation_result=$?
      set -e # Re-enable error checking
      if [ $validation_result -ne 0 ]; then
        echo "${BOLD}${RED}❌ Invalid password provided in '.vault-password' file. Please check your password and try again.${RESET}" >&2
        exit $validation_result
      fi
    fi

    if [[ "$run_type" == "local" ]]; then
      vault_args+=("--vault-password-file" ".vault-password")
    else
      vault_args+=("--vault-password-file" "/ansible/.vault-password")
    fi
  elif is_encrypted_with_ansible_vault "$variable_file" || is_encrypted_with_ansible_vault ".spin-inventory.ini"; then
    echo "${BOLD}${YELLOW}🔐 '.vault-password' file not found. You will be prompted to enter your vault password.${RESET}" >&2
    vault_args+=("--ask-vault-pass")
  fi

  echo "${vault_args[@]}"
}

setup_color() {
    # Disable debug tracing temporarily
    { set +x; } 2>/dev/null

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
    MAGENTA=$(printf '\033[1;35m')

    # Restore debug tracing if it was enabled
    if [[ "${SPIN_DEBUG:-false}" == "true" ]]; then
        set -x
    fi
}

show_existing_files_warning() {
  if [ $? -eq 0 ]; then
    echo "${BOLD}${MAGENTA}🚨 COMPLETED WITH WARNINGS:${RESET}"
    echo "${BOLD}${YELLOW}👉 Some files already existed when copying the template, so we left those files alone.${RESET}"
    echo "${BOLD}${YELLOW}👉 Check the output above to figure out what files you may need to update manually.${RESET}"
  fi
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

validate_project_setup() {

  validate_spin_yml

  # Validate infrastructure folder is present
  if [ ! -d ".infrastructure" ]; then
      echo "${BOLD}${RED}❌ Infrastructure folder not found${RESET}"
      echo "Please ensure you're in the root of your project."
      return 1
  fi

  # Create ci folder if it doesn't exist
  if [ ! -d "$SPIN_CI_FOLDER" ] || [ ! -f "$SPIN_CI_FOLDER/.gitignore" ]; then
    echo "${BOLD}${YELLOW}⚠️ Warning: The CI folder is missing, we will create this for you.${RESET}"
    mkdir -p "$SPIN_CI_FOLDER"
    echo "*" > "$SPIN_CI_FOLDER/.gitignore"
    echo "!.gitignore" >> "$SPIN_CI_FOLDER/.gitignore"
  fi

  return 0
}

validate_spin_yml() {
  if [ ! -f ".spin.yml" ]; then
    echo "${BOLD}${RED}❌ .spin.yml not found${RESET}"
    echo "Please ensure you're in the root of your project and a .spin.yml file exists."
    return 1
  fi

  if is_encrypted_with_ansible_vault ".spin.yml" && \
    [ ! -f ".vault-password" ]; then
        echo "${BOLD}${RED}❌Error: .spin.yml is encrypted with Ansible Vault, but '.vault-password' file is missing.${RESET}"
        echo "${BOLD}${YELLOW}Please save your vault password in '.vault-password' in your project root and try again.${RESET}"
        return 1
  fi

  return 0
}
