#!/usr/bin/env bash

################################################################################
# Helper functions
################################################################################
cleanup_on_exit() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo "❌ Failure detected. Cleaning up local services..."
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
        
        # Clean up unused images
        echo "${BOLD}${BLUE}🧹 Cleaning up unused Docker images on $manager_host...${RESET}"
        if docker -H "$docker_host" image prune -f; then
            echo "${BOLD}${BLUE}✨ Successfully cleaned up unused Docker images.${RESET}"
        else
            echo "${BOLD}${YELLOW}⚠️ Warning: Failed to clean up unused Docker images.${RESET}"
        fi
    else
        echo "${BOLD}${RED}❌ Failed to deploy Docker stack on $manager_host.${RESET}"
        exit 1
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

stop_registry() {
    if docker ps -q -f name="$spin_registry_name" | grep -q .; then
        echo "Stopping local Docker registry..."
        docker stop "$spin_registry_name" >/dev/null 2>&1
        echo "Local Docker registry stopped."
    fi
}

################################################################################
# Main deploy action
################################################################################

action_deploy() {
    compose_files=()
    deployment_environment=""
    deployment_environment_uppercase=""
    spin_registry_name="spin-registry"
    env_file=""
    force_ansible_upgrade=false
    
    validate_project_setup

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --user | -u)
            SPIN_SSH_USER="$2"
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
            SPIN_SSH_PORT="$2"
            shift 2
            ;;
        --upgrade|-U)
            SPIN_FORCE_INSTALL_GALAXY_DEPS=true
            shift
            ;;
        -*)
            echo "${BOLD}${RED}❌Error: Unknown option $1${RESET}"
            exit 1
            ;;
        *)
            # Only set deployment_environment if it hasn't been set yet
            if [[ -z "$deployment_environment" ]]; then
                deployment_environment="$1"
            fi
            shift
            ;;
        esac
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

    # Set an uppercase version of the deployment environment
    deployment_environment_uppercase=$(echo "$deployment_environment" | tr '[:lower:]' '[:upper:]')

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
    image_prefix="${SPIN_BUILD_IMAGE_PREFIX:-"127.0.0.1:$registry_port"}"
    image_tag="${SPIN_BUILD_TAG:-$(date +%Y%m%d%H%M%S)}"
    ssh_port="${SPIN_SSH_PORT:-22}"
    ssh_user="${SPIN_SSH_USER:-"deploy"}"
    spin_project_name="${SPIN_PROJECT_NAME:-"spin"}"
    registry_image="${SPIN_REGISTRY_IMAGE:-"registry:2"}"

    # Clean up services on exit
    trap cleanup_on_exit EXIT

    # Check if any Dockerfiles exist (using safer glob handling)
    shopt -s nullglob
    dockerfiles=( Dockerfile* )
    shopt -u nullglob
    if [[ ${#dockerfiles[@]} -gt 0 ]]; then
        # Bring up a local docker registry
        if [ -z "$(docker ps -q -f name=$spin_registry_name)" ]; then
            # Ensure the registry cache directory exists with the correct user and group ID
            mkdir -p "$SPIN_CACHE_DIR/registry"

            # Start the registry with the correct user and group ID
            echo "${BOLD}${BLUE}🚀 Starting local Docker registry...${RESET}"
            docker run --rm -d -p "$registry_port:5000" --user "${SPIN_USER_ID}:${SPIN_GROUP_ID}" -v "$SPIN_CACHE_DIR/registry:/var/lib/registry" --name "$spin_registry_name" "$registry_image"
        fi

        # Build and push each Dockerfile
        for dockerfile in "${dockerfiles[@]}"; do
            # Generate variable name based on Dockerfile name
            spin_image_var_name=$(echo "$dockerfile" | tr '[:lower:].' '[:upper:]_')
            spin_image_var_name="SPIN_IMAGE_${spin_image_var_name}"

            # Set and export image name
            full_docker_image_name="${image_prefix}/$(echo "$dockerfile" | tr '[:upper:]' '[:lower:]')"
            versioned_image="${full_docker_image_name}:${image_tag}"
            latest_image="${full_docker_image_name}:latest"
            
            # Export the versioned image name for other scripts to use
            export "$spin_image_var_name=$versioned_image"

            # Build and tag the Docker image with both tags
            echo "${BOLD}${BLUE}🐳 Building Docker image '$versioned_image' from '$dockerfile'...${RESET}"
            if docker buildx build --push --platform "$build_platform" \
                -t "$versioned_image" \
                -t "$latest_image" \
                -f "$dockerfile" .; then
                echo "${BOLD}${BLUE}📦 Successfully built '$versioned_image' from '$dockerfile'...${RESET}"
            else
                echo "${BOLD}${RED}❌ Failed to build '$versioned_image' from '$dockerfile'.${RESET}"
                exit 1
            fi
        done
    else
        echo "${BOLD}${YELLOW}🐳 No Dockerfiles found in the directory. Skipping Docker image build...${RESET}"
    fi

    # Get deployment host information
    echo "${BOLD}${BLUE}📡 Getting deployment host information for \"$deployment_environment\"...${RESET}"
    prepare_ansible_run "$@"
    run_ansible --mount-path "$(pwd):/ansible" \
      ansible-playbook serversideup.spin.prepare_ci_environment \
      --inventory "$SPIN_INVENTORY_FILE" \
      --extra-vars @./.spin.yml \
      --extra-vars "spin_environment=$deployment_environment" \
      --extra-vars "spin_ci_folder=$SPIN_CI_FOLDER" \
      --tags "get-host,get-authorized-keys" \
      "${SPIN_ANSIBLE_ARGS[@]}" \
      "${SPIN_UNPROCESSED_ARGS[@]}"

    docker_swarm_manager=$(cat "$SPIN_CI_FOLDER/${deployment_environment_uppercase}_SSH_REMOTE_HOSTNAME")

    # Read and export authorized keys
    if [[ -f "$SPIN_CI_FOLDER/AUTHORIZED_KEYS" ]]; then
        # Read the file content and escape newlines for Docker
        AUTHORIZED_KEYS=$(awk 1 ORS='\\n' "$SPIN_CI_FOLDER/AUTHORIZED_KEYS" | sed 's/\\n$//')
        export AUTHORIZED_KEYS
        echo "${BOLD}${BLUE} Authorized keys loaded and exported as AUTHORIZED_KEYS${RESET}"
    else
        echo "${BOLD}${YELLOW}⚠️  Warning: No AUTHORIZED_KEYS file found in $SPIN_CI_FOLDER${RESET}"
    fi

    if [ $? -ne 0 ] || [ -z "$docker_swarm_manager" ]; then
        echo "${BOLD}${RED}❌ Error: Failed to get a valid swarm manager host for group '$deployment_environment'.${RESET}" >&2
        exit 1
    else
        echo "${BOLD}${GREEN}✅ Deploying to Swarm Manager: $docker_swarm_manager${RESET}"
    fi

    # Create SSH tunnel to Docker registry
    echo "${BOLD}${BLUE}🚇 Creating SSH tunnel to Docker registry...${RESET}"
    
    # Build SSH command with proper quoting
    ssh_cmd=(
        ssh -f -n -N 
        -R "${registry_port}:127.0.0.1:${registry_port}"
        -p "${ssh_port}"
        "${ssh_user}@${docker_swarm_manager}"
        -o ExitOnForwardFailure=yes
        -o ServerAliveInterval=60
        -o ServerAliveCountMax=3
        -o StrictHostKeyChecking=accept-new
    )
    
    if "${ssh_cmd[@]}"; then
        echo "${BOLD}${GREEN}✅ SSH tunnel created successfully${RESET}"
        echo "${BOLD}${BLUE}ℹ️ Tunnel details:${RESET}"
        echo "   🔗 Local port: ${registry_port}"
        echo "   🖥️  Remote host: ${docker_swarm_manager}"
        echo "   🔌 Remote port: ${registry_port}"
        echo "   👤 SSH user: ${ssh_user}"
        echo "   🔢 SSH port: ${ssh_port}"
        echo "${BOLD}${BLUE}🔄 The tunnel will forward connections from the remote port ${registry_port} to 127.0.0.1:${registry_port}${RESET}"
    else
        ssh_exit_code=$?
        echo "${BOLD}${RED}❌ Failed to create SSH tunnel (Exit code: $ssh_exit_code)${RESET}"
        echo "${BOLD}${YELLOW}🔧 Troubleshoot your connection by running:${RESET}"
        echo "${BOLD}${YELLOW}ssh -v -p ${ssh_port} ${ssh_user}@${docker_swarm_manager}${RESET}"
        exit 1
    fi

    # Get the process ID of the SSH tunnel using POSIX-compliant commands
    tunnel_pid=$(ps aux | grep "ssh -f -n -N -R ${registry_port}:127.0.0.1:${registry_port}" | grep -v grep | awk '{print $2}')

    echo "${BOLD}${BLUE}🚀 Deploying Docker stack...${RESET}"
    deploy_docker_stack "$docker_swarm_manager" "$ssh_port"
    stop_registry
    cleanup_ssh_tunnel
    echo "${BOLD}${GREEN}✅ Docker stack deployment completed.${RESET}"
}