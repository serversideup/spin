#!/usr/bin/env bash
action_deploy(){
    compose_files=""
    deployment_environment=""
    registry_port="${SPIN_REGISTRY_PORT:-5000}"
    build_platform="${SPIN_BUILD_PLATFORM:-"linux/amd64"}"
    image_suffix=''
    image_prefix="${SPIN_BUILD_IMAGE_PREFIX:-"localhost:$registry_port"}"
    image_tag="${SPIN_BUILD_TAG:-"latest"}"
    inventory_file="${SPIN_INVENTORY_FILE:-"/ansible/.spin-inventory.ini"}"
    ssh_port="${SPIN_SSH_PORT:-''}" # Default to empty string
    ssh_user="${SPIN_SSH_USER:-"deploy"}"
    spin_registry_name="spin-registry"
    spin_project_name="${SPIN_PROJECT_NAME:-"spin"}"
    use_default_compose_files=true
    traefik_config_file="${SPIN_TRAEFIK_CONFIG_FILE:-"$(pwd)/.infrastructure/conf/traefik/prod/traefik.yml"}"

    cleanup_registry() {
        if [ -n "$tunnel_pid" ]; then
            # Check if the process is still running
            if ps -p "$tunnel_pid" > /dev/null; then
                kill "$tunnel_pid"
            else
                echo "Process $tunnel_pid not running."
            fi
        fi
        docker stop "$spin_registry_name" > /dev/null 2>&1
    }

    deploy_docker_stack() {
        local manager_host="$1"
        local ssh_port="$2"
        local compose_args=""

        if [[ "$use_default_compose_files" = true ]]; then
            compose_files=("docker-compose.yml" "docker-compose.prod.yml")
        fi

        for compose_file in "${compose_files[@]}"; do
            compose_args+=" --compose-file $compose_file"
        done

        local docker_host="ssh://$ssh_user@$manager_host:$ssh_port"
        echo "${BOLD}${BLUE}📤 Deploying Docker stack with compose files: ${compose_files[*]} on $manager_host...${RESET}"
        docker -H "$docker_host" stack deploy $compose_args --detach=false --prune "$spin_project_name-$deployment_environment"
        if [ $? -eq 0 ]; then
            echo "${BOLD}${BLUE}🎉 Successfully deployed Docker stack on $manager_host.${RESET}"
        else
            echo "${BOLD}${RED}❌ Failed to deploy Docker stack on $manager_host.${RESET}"
            exit 1
        fi
    }

    get_hosts_from_ansible() {
        run_ansible --mount-path $(pwd) \
        ansible \
            $1 \
            --inventory-file $inventory_file \
            --module-name ping \
            --list-hosts \
            $additional_ansible_args \
            | awk 'NR>1 {gsub(/\r/,""); print $1}'
    }

    trap cleanup_registry EXIT

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user|-u)
                ssh_user="$2"
                shift 2
                ;;
            --compose-file|-c)
                use_default_compose_files=false
                if [[ -n "$2" && "$2" != -* ]]; then
                    compose_files+=("$2")
                    shift 2
                else
                    echo "${BOLD}${RED}❌Error: '-c' option requires a Docker Compose file as argument.${RESET}"
                    exit 1
                fi
                ;;
            --port|-p)
                ssh_port="$2"
                shift 2
                ;;
            *)
                if [[ -z "$deployment_environment" ]]; then  # capture the first positional argument as environment
                    deployment_environment="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate target environment
    if [[ -z "$deployment_environment" ]]; then
        echo "${BOLD}${YELLOW}You didn't pass 'spin deploy' an environment to deploy to. Run 'spin help' if you want to see the documentation.${RESET}"
        exit 1
    fi

    # Check if any Dockerfiles exist
    if [ -z "$(ls Dockerfile* 2>/dev/null)" ]; then
        echo "${BOLD}${YELLOW}❌ No Dockerfiles found in this directory. Be sure to run \"spin deploy\" in your project root.${RESET}"
        exit 1
    fi

    # Bring up a local docker registry
    if [ -z "$(docker ps -q -f name=$spin_registry_name)" ]; then
        echo "${BOLD}${BLUE}🚀 Starting local Docker registry...${RESET}"
        docker run --rm -d -p $registry_port:5000 -v "$SPIN_CACHE_DIR/registry:/var/lib/registry" --name $spin_registry_name registry:2
    fi

    # Prepare the Ansible run
    prepare_ansible_run
    
    # Set and export image name
    image_name="${image_prefix}/dockerfile:${image_tag}"
    SPIN_IMAGE_NAME="${image_name}"
    export SPIN_IMAGE_NAME

        # Set the Traefik MD5 variable
    if [ -f "$(pwd)/.infrastructure/conf/traefik/prod/traefik.yml" ]; then
        traefik_config_file="${SPIN_TRAEFIK_CONFIG_FILE:-"$(pwd)/.infrastructure/conf/traefik/prod/traefik.yml"}"
    else
        traefik_config_file="${SPIN_TRAEFIK_CONFIG_FILE}"
    fi

    traefik_config_md5_hash=$(get_md5_hash "$traefik_config_file")
    SPIN_TRAEFIK_CONFIG_MD5_HASH="${traefik_config_md5_hash}"
    export SPIN_TRAEFIK_CONFIG_MD5_HASH

    # Build the Docker image
    local dockerfile="Dockerfile"
    echo "${BOLD}${BLUE}🐳 Building Docker image '$image_name' from '$dockerfile'...${RESET}"
    docker buildx build --push --platform "$build_platform" -t "$image_name" -f "$dockerfile" .
    if [ $? -eq 0 ]; then
        echo "${BOLD}${BLUE}📦 Successfully built '$image_name' from '$dockerfile'...${RESET}"
    else
        echo "${BOLD}${RED}❌ Failed to build '$image_name' from '$dockerfile'.${RESET}"
        exit 1
    fi

    # Prepare SSH connection
    if [[ -n "$ssh_port" ]]; then
        ssh_port="$(get_ansible_variable "ssh_port")"
    fi
    swarm_manager_group="${SPIN_SWARM_MANAGER_GROUP:-"${deployment_environment}_manager_servers"}"
    docker_swarm_manager=$(get_hosts_from_ansible "$swarm_manager_group" | head -n 1)

    # Create SSH tunnel to Docker registry
    if ! ssh -f -n -N -R "${registry_port}:localhost:${registry_port}" -p "${ssh_port}" "${ssh_user}@${docker_swarm_manager}" -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3; then
        echo "${BOLD}${RED}Failed to create SSH tunnel. Exiting...${RESET}"
        exit 1
    fi

    # Get the process ID of the SSH tunnel
    tunnel_pid=$(pgrep -f "ssh -f -n -N -R ${registry_port}:localhost:${registry_port}")
    
    deploy_docker_stack "$docker_swarm_manager" "$ssh_port"

}