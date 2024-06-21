#!/usr/bin/env bash

if [[ -f ".env" ]]; then
    eval export $(cat .env)
fi

action_deploy() {
    compose_files=""
    deployment_environment=""
    registry_port="${SPIN_REGISTRY_PORT:-5000}"
    build_platform="${SPIN_BUILD_PLATFORM:-"linux/amd64"}"
    image_prefix="${SPIN_BUILD_IMAGE_PREFIX:-"localhost:$registry_port"}"
    image_tag="${SPIN_BUILD_TAG:-"latest"}"
    inventory_file="${SPIN_INVENTORY_FILE:-"/ansible/.spin-inventory.ini"}"
    ssh_port="${SPIN_SSH_PORT:-''}" # Default to empty string
    ssh_user="${SPIN_SSH_USER:-"deploy"}"
    spin_registry_name="spin-registry"
    spin_project_name="${SPIN_PROJECT_NAME:-"spin"}"
    use_default_compose_files=true

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
        local compose_args=""

        if [[ "$use_default_compose_files" = true ]]; then
            compose_files=("docker-compose.yml" "docker-compose.prod.yml")
        fi
        if [[ ${#compose_files[@]} -gt 0 ]]; then
            for compose_file in "${compose_files[@]}"; do
                if [[ -n "$compose_file" ]]; then
                    # Compute MD5 hashes if necessary
                    generate_md5_hashes "$compose_file"
                    compose_args+=" --compose-file $compose_file"
                fi
            done
        fi

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
        local vault_args=()
        local host_group="$1"

        # Read the vault arguments into an array
        read -r -a vault_args < <(ansible_vault_args)

        # Run the Ansible command to get the list of hosts
        run_ansible --mount-path $(pwd) \
            ansible \
            "$host_group" \
            --inventory-file "$inventory_file" \
            --module-name ping \
            --list-hosts \
            "${vault_args[@]}" |
            awk 'NR>1 {gsub(/\r/,""); print $1}'
    }

    trap cleanup_registry EXIT

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --user | -u)
            ssh_user="$2"
            shift 2
            ;;
        --compose-file | -c)
            use_default_compose_files=false
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

    # Validate target environment
    if [[ -z "$deployment_environment" ]]; then
        echo "${BOLD}${YELLOW}You didn't pass 'spin deploy' an environment to deploy to. Run 'spin help' if you want to see the documentation.${RESET}"
        exit 1
    fi

    # Check if any Dockerfiles exist
    if [ -n "$(ls Dockerfile* 2>/dev/null)" ]; then
        # Bring up a local docker registry
        if [ -z "$(docker ps -q -f name=$spin_registry_name)" ]; then
            echo "${BOLD}${BLUE}🚀 Starting local Docker registry...${RESET}"
            docker run --rm -d -p $registry_port:5000 -v "$SPIN_CACHE_DIR/registry:/var/lib/registry" --name $spin_registry_name registry:2
        fi

        # Prepare the Ansible run
        check_galaxy_pull

        # Set and export image name
        image_name="${image_prefix}/dockerfile:${image_tag}"
        SPIN_IMAGE_NAME="${image_name}"
        export SPIN_IMAGE_NAME

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
    else
        echo "${BOLD}${BLUE} No Dockerfiles found in this directory, skipping Docker image build"
    fi

    # Prepare SSH connection
    echo "${BOLD}${BLUE} Setting up SSH tunnel to Docker registry...${RESET}"

    if [[ -n "$ssh_port" ]]; then
        ssh_port="$(get_ansible_variable "ssh_port")"
    fi
    swarm_manager_group="${SPIN_SWARM_MANAGER_GROUP:-"${deployment_environment}_manager_servers"}"
    docker_swarm_manager=$(get_hosts_from_ansible "$swarm_manager_group" | head -n 1)

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
