#!/usr/bin/env bash
action_deploy() {
    compose_files=()
    deployment_environment=""
    spin_registry_name="spin-registry"
    env_file=""

    # First, find the deployment environment
    for arg in "$@"; do
        if [[ "$arg" != -* && -z "$deployment_environment" ]]; then
            deployment_environment="$arg"
            break
        fi
    done

    # If no environment specified, default to production
    if [[ -z "$deployment_environment" ]]; then
        echo "${BOLD}${BLUE}Defaulting to \"production\" as the deployment environment...${RESET}"
        deployment_environment="production"
    fi

    SPIN_DEPLOYMENT_ENVIRONMENT="$deployment_environment"
    export SPIN_DEPLOYMENT_ENVIRONMENT

    # Attempt to load environment variables
    if [[ -f ".env.$SPIN_DEPLOYMENT_ENVIRONMENT" ]]; then
        env_file=".env.$SPIN_DEPLOYMENT_ENVIRONMENT"
        echo "${BOLD}${BLUE}Loading environment variables from $env_file...${RESET}"
    elif [[ -f ".env" ]]; then
        env_file=".env"
        echo "${BOLD}${YELLOW}Warning: .env.$SPIN_DEPLOYMENT_ENVIRONMENT not found. Falling back to $env_file...${RESET}"
    else
        echo "${BOLD}${YELLOW}Warning: Neither .env.$SPIN_DEPLOYMENT_ENVIRONMENT nor .env found. Proceeding with default values...${RESET}"
    fi

    # Source the env file if it exists
    if [[ -n "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
    fi

    # Set SPIN_APP_DOMAIN if APP_URL is set
    if [[ -n "$APP_URL" ]]; then
        # Remove http:// or https:// from the beginning of the URL
        SPIN_APP_DOMAIN=$(echo "$APP_URL" | sed -E 's#^https?://##')
        # Remove any path, query parameters, or port after the domain
        SPIN_APP_DOMAIN=$(echo "$SPIN_APP_DOMAIN" | awk -F[/:] '{print $1}')
        if [[ -n "$SPIN_APP_DOMAIN" ]]; then
            export SPIN_APP_DOMAIN
            echo "${BOLD}${BLUE}SPIN_APP_DOMAIN set to: $SPIN_APP_DOMAIN${RESET}"
        else
            echo "${BOLD}${YELLOW}Warning: Could not extract domain from APP_URL. SPIN_APP_DOMAIN will not be set.${RESET}"
        fi
    else
        echo "${BOLD}${YELLOW}Warning: APP_URL not set. SPIN_APP_DOMAIN will not be available.${RESET}"
    fi

    # Set default values (can be overridden by .env file or command line arguments)
    registry_port="${SPIN_REGISTRY_PORT:-5080}"
    build_platform="${SPIN_BUILD_PLATFORM:-"linux/amd64"}"
    image_prefix="${SPIN_BUILD_IMAGE_PREFIX:-"localhost:$registry_port"}"
    image_tag="${SPIN_BUILD_TAG:-"latest"}"
    inventory_file="${SPIN_INVENTORY_FILE:-"/ansible/.spin-inventory.ini"}"
    ssh_port="${SPIN_SSH_PORT:-''}"
    ssh_user="${SPIN_SSH_USER:-"deploy"}"
    spin_project_name="${SPIN_PROJECT_NAME:-"spin"}"

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --user | -u)
            ssh_user="$2"
            shift 2
            ;;
        --compose-file | -c)
            if [[ -n "$2" && "$2" != -* ]]; then
                compose_files+=("$2")
                shift 2
            else
                echo "${BOLD}${RED}❌Error: '-c' option requires a Docker Compose file as argument.${RESET}"
                exit 1
            fi
            ;;
        --port | -p)
            ssh_port="$2"
            shift 2
            ;;
        *)
            if [[ -z "$deployment_environment" ]]; then # capture the first positional argument as environment
                deployment_environment="$1"
            fi
            shift
            ;;
        esac
    done

    cleanup_registry() {
        if [ -n "$tunnel_pid" ]; then
            # Check if the process is still running
            if ps -p "$tunnel_pid" >/dev/null; then
                kill "$tunnel_pid"
            else
                echo "Process $tunnel_pid not running."
            fi
        fi
        docker stop "$spin_registry_name" >/dev/null 2>&1
    }

    generate_md5_hashes() {
        # Check if the configs key exists
        if grep -q 'configs:' "$compose_file"; then
            # Extract config file paths
            local config_files
            config_files=$(awk '/configs:/{flag=1;next}/^[^ ]/{flag=0}flag' "$compose_file" | grep 'file:' | awk '{print $2}')

            for config_file_path in $config_files; do
                if [ -f "$config_file_path" ]; then
                    local config_md5_hash
                    config_md5_hash=$(get_md5_hash "$config_file_path" | awk '{ print $1 }')
                    config_md5_var="SPIN_MD5_HASH_$(basename "$config_file_path" | tr '[:lower:]' '[:upper:]' | tr '.' '_')"

                    eval "$config_md5_var=$config_md5_hash"
                    export $config_md5_var
                fi
            done
        fi
    }

    deploy_docker_stack() {
        local manager_host="$1"
        local ssh_port="$2"
        local compose_args=()

        # Set default compose files if none were provided
        if [[ ${#compose_files[@]} -eq 0 ]]; then
            compose_files=("docker-compose.yml" "docker-compose.prod.yml")
        fi

        # Build the compose arguments
        for compose_file in "${compose_files[@]}"; do
            if [[ -n "$compose_file" ]]; then
                # Compute MD5 hashes if necessary
                generate_md5_hashes "$compose_file"
                compose_args+=("--compose-file" "$compose_file")
            fi
        done

        local docker_host="ssh://$ssh_user@$manager_host:$ssh_port"
        echo "${BOLD}${BLUE}📤 Deploying Docker stack with compose files: ${compose_files[*]} on $manager_host...${RESET}"
        docker -H "$docker_host" stack deploy "${compose_args[@]}" --detach=false --prune "$spin_project_name-$deployment_environment"
        if [ $? -eq 0 ]; then
            echo "${BOLD}${BLUE}🎉 Successfully deployed Docker stack on $manager_host.${RESET}"
        else
            echo "${BOLD}${RED}❌ Failed to deploy Docker stack on $manager_host.${RESET}"
            exit 1
        fi
    }

    get_ansible_hosts() {
        local host_group="$1"
        local output
        local exit_code

        # Run the Ansible command to get the list of hosts and capture both output and exit code
        output=$(run_ansible --mount-path "$(pwd)" \
            ansible \
            "$host_group" \
            --inventory-file "$inventory_file" \
            --module-name ping \
            --list-hosts \
            $(ansible_vault_args) 2>&1)
        exit_code=$?

        # Check for errors or no hosts
        if echo "$output" | grep -q "No hosts matched, nothing to do" || [ $exit_code -ne 0 ]; then
            echo "Error: Failed to retrieve hosts for group '$host_group'." >&2
            echo "Ansible output: $output" >&2
            return 1
        fi

        # Process and return the output if successful
        echo "$output" | awk 'NR>1 {gsub(/\r/,""); print $1}'
    }

    trap cleanup_registry EXIT

    # Check if any Dockerfiles exist
    dockerfiles=$(ls Dockerfile* 2>/dev/null)
    if [[ -n "$dockerfiles" ]]; then
        # Bring up a local docker registry
        if [ -z "$(docker ps -q -f name=$spin_registry_name)" ]; then
            echo "${BOLD}${BLUE}🚀 Starting local Docker registry...${RESET}"
            docker run --rm -d -p "$registry_port:5000" -v "$SPIN_CACHE_DIR/registry:/var/lib/registry" --name $spin_registry_name registry:2
        fi

        # Prepare the Ansible run
        check_galaxy_pull

        # Build and push each Dockerfile
        for dockerfile in $dockerfiles; do
            # Generate variable name based on Dockerfile name
            var_name=$(echo "$dockerfile" | tr '[:lower:].' '[:upper:]_')
            var_name="SPIN_IMAGE_${var_name}"

            # Set and export image name
            image_name="${image_prefix}/$(echo "$dockerfile" | tr '[:upper:]' '[:lower:]'):${image_tag}"
            export "$var_name=$image_name"

            # Build the Docker image
            echo "${BOLD}${BLUE}🐳 Building Docker image '$image_name' from '$dockerfile'...${RESET}"
            docker buildx build --push --platform "$build_platform" -t "$image_name" -f "$dockerfile" .
            if [ $? -eq 0 ]; then
                echo "${BOLD}${BLUE}📦 Successfully built '$image_name' from '$dockerfile'...${RESET}"
            else
                echo "${BOLD}${RED}❌ Failed to build '$image_name' from '$dockerfile'.${RESET}"
                exit 1
            fi
        done
    else
        echo "${BOLD}${BLUE} No Dockerfiles found in this directory, skipping Docker image build"
    fi

    # Prepare SSH connection
    echo "${BOLD}${BLUE} Setting up SSH tunnel to Docker registry...${RESET}"

    if [[ -n "$ssh_port" ]]; then
        ssh_port="$(get_ansible_variable "ssh_port")"
    fi
    swarm_manager_group="${SPIN_SWARM_MANAGER_GROUP:-"${deployment_environment}_manager_servers"}"
    docker_swarm_manager=$(get_ansible_hosts "$swarm_manager_group" | head -n 1)

    if [ $? -ne 0 ] || [ -z "$docker_swarm_manager" ]; then
        echo "${BOLD}${RED}Error: Failed to get a valid swarm manager host for group '$swarm_manager_group'.${RESET}" >&2
        echo "${BOLD}${RED}Please check if the environment '$deployment_environment' exists in '$(basename "$inventory_file")'.${RESET}" >&2
        exit 1
    fi

    # Create SSH tunnel to Docker registry
    if ! ssh -f -n -N -R "${registry_port}:localhost:${registry_port}" -p "${ssh_port}" "${ssh_user}@${docker_swarm_manager}" -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3; then
        echo "${BOLD}${RED}Failed to create SSH tunnel. Exiting...${RESET}"
        echo "${BOLD}${YELLOW}Troubleshoot your connection by running:${RESET}"
        echo "${BOLD}${YELLOW}ssh -p $ssh_port $ssh_user@$docker_swarm_manager${RESET}"
        exit 1
    fi

    # Get the process ID of the SSH tunnel
    tunnel_pid=$(pgrep -f "ssh -f -n -N -R ${registry_port}:localhost:${registry_port}")

    echo "${BOLD}${BLUE} SSH tunnel to Docker registry established.${RESET}"

    deploy_docker_stack "$docker_swarm_manager" "$ssh_port"
}
