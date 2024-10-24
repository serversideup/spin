#!/usr/bin/env bash
action_deploy() {
    compose_files=()
    deployment_environment=""
    spin_registry_name="spin-registry"
    env_file=""
    force_ansible_upgrade=false
    if is_encrypted_with_ansible_vault ".spin.yml" && \
    [ ! -f ".vault-password" ]; then
        echo "${BOLD}${RED}❌Error: .spin.yml is encrypted with Ansible Vault, but '.vault-password' file is missing.${RESET}"
        echo "${BOLD}${YELLOW}Please save your vault password in '.vault-password' in your project root and try again.${RESET}"
        exit 1
    fi

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
        --upgrade|-U)
            force_ansible_upgrade=true
            shift
            ;;
        *)
            if [[ -z "$deployment_environment" ]]; then # capture the first positional argument as environment
                deployment_environment="$1"
            fi
            shift
            ;;
        esac
    done

    stop_registry() {
        if docker ps -q -f name="$spin_registry_name" | grep -q .; then
            echo "Stopping local Docker registry..."
            docker stop "$spin_registry_name" >/dev/null 2>&1
            echo "Local Docker registry stopped."
        fi
    }

    cleanup_on_exit() {
        local exit_code=$?

        if [ $exit_code -ne 0 ]; then
            echo "Failure detected. Cleaning up local services..."
        fi
        stop_registry
        cleanup_ssh_tunnel

        exit $exit_code
    }

    cleanup_ssh_tunnel() {
        if [ -n "$tunnel_pid" ]; then
            # Check if the process is still running
            if ps -p "$tunnel_pid" > /dev/null; then
                echo "Stopping local SSH tunnel..."
                kill "$tunnel_pid"
                echo "Local SSH tunnel stopped."
            fi
        fi
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
            $(set_ansible_vault_args) 2>&1)
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

    # Clean up services on exit
    trap cleanup_on_exit EXIT

    # Check if any Dockerfiles exist
    dockerfiles=$(ls Dockerfile* 2>/dev/null)
    if [[ -n "$dockerfiles" ]]; then
        # Bring up a local docker registry
        if [ -z "$(docker ps -q -f name=$spin_registry_name)" ]; then
            # Ensure the registry cache directory exists with the correct user and group ID
            mkdir -p "$SPIN_CACHE_DIR/registry"

            # Start the registry with the correct user and group ID
            echo "${BOLD}${BLUE}🚀 Starting local Docker registry...${RESET}"
            docker run --rm -d -p "$registry_port:5000" --user "${SPIN_USER_ID}:${SPIN_GROUP_ID}" -v "$SPIN_CACHE_DIR/registry:/var/lib/registry" --name $spin_registry_name registry:2
        fi

        # Prepare the Ansible run
        check_galaxy_pull "$force_ansible_upgrade"

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
        echo "${BOLD}${RED} No Dockerfiles found in the directory. Be sure you're running this command from the project root.${RESET}"
        exit 1
    fi

    # Prepare SSH connection
    echo "${BOLD}${BLUE}⚡️ Setting up SSH tunnel to Docker registry...${RESET}"

    if [[ -n "$ssh_port" ]]; then
        if ! ssh_port=$(get_ansible_variable "ssh_port"); then
            echo "${BOLD}${RED}❌ Error: Failed to get SSH port from Ansible variables.${RESET}" >&2
            exit 1
        fi
        echo "   ℹ️ Using SSH port: $ssh_port"
    else
        echo "   ℹ️ Using default SSH port"
    fi

    swarm_manager_group="${SPIN_SWARM_MANAGER_GROUP:-"${deployment_environment}_manager_servers"}"
    echo "${BOLD}${BLUE}🔍 Looking for swarm manager in group: $swarm_manager_group${RESET}"

    docker_swarm_manager=$(get_ansible_hosts "$swarm_manager_group" | head -n 1)

    if [ $? -ne 0 ] || [ -z "$docker_swarm_manager" ]; then
        echo "${BOLD}${RED}❌ Error: Failed to get a valid swarm manager host for group '$swarm_manager_group'.${RESET}" >&2
        echo "${BOLD}${RED}Please check if the environment '$deployment_environment' exists in '$(basename "$inventory_file")'.${RESET}" >&2
        exit 1
    else
        echo "${BOLD}${GREEN}✅ Found swarm manager: $docker_swarm_manager${RESET}"
    fi

    # Create SSH tunnel to Docker registry
    echo "${BOLD}${BLUE}🚇 Creating SSH tunnel to Docker registry...${RESET}"
    if ssh -f -n -N -R "${registry_port}:localhost:${registry_port}" -p "${ssh_port}" "${ssh_user}@${docker_swarm_manager}" -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3; then
        echo "${BOLD}${GREEN}✅ SSH tunnel created successfully${RESET}"
        echo "${BOLD}${BLUE}ℹ️ Tunnel details:${RESET}"
        echo "   🔗 Local port: ${registry_port}"
        echo "   🖥️  Remote host: ${docker_swarm_manager}"
        echo "   🔌 Remote port: ${registry_port}"
        echo "   👤 SSH user: ${ssh_user}"
        echo "   🔢 SSH port: ${ssh_port}"
        echo "${BOLD}${BLUE}🔄 The tunnel will forward connections from the remote port ${registry_port} to localhost:${registry_port}${RESET}"
    else
        echo "${BOLD}${RED}❌ Failed to create SSH tunnel. Exiting...${RESET}"
        echo "${BOLD}${YELLOW}🔧 Troubleshoot your connection by running:${RESET}"
        echo "${BOLD}${YELLOW}ssh -p $ssh_port $ssh_user@$docker_swarm_manager${RESET}"
        exit 1
    fi

    # Get the process ID of the SSH tunnel
    tunnel_pid=$(pgrep -f "ssh -f -n -N -R ${registry_port}:localhost:${registry_port}")

    echo "${BOLD}${BLUE}🚀 Deploying Docker stack...${RESET}"
    deploy_docker_stack "$docker_swarm_manager" "$ssh_port"
    stop_registry
    cleanup_ssh_tunnel
    echo "${BOLD}${GREEN}✅ Docker stack deployment completed.${RESET}"
}