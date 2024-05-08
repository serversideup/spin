#!/usr/bin/env bash
action_deploy(){
    deployment_environment=""
    build_platform="${SPIN_BUILD_PLATFORM:-"linux/amd64"}"
    image_suffix=''
    image_prefix="${SPIN_BUILD_IMAGE_PREFIX:-local.docker}"
    inventory_file="${SPIN_INVENTORY_FILE:-"/ansible/.spin-inventory.ini"}"
    ssh_port="${SPIN_SSH_PORT:-''}" # Default to empty string
    ssh_user="${SPIN_SSH_USER:-"deploy"}"
    
    # Set environment variables for Docker Compose usage
    SPIN_BUILD_TAG="${build_tag}"
    export SPIN_BUILD_TAG
    declare -a compose_files  # Declare an array to store Docker Compose files

    dockerImageNeedsUpdate() {
        image_name="$1"
        host="$2"
        remote_image_id=$(ssh -p "$ssh_port" "$ssh_user@$host" docker inspect --format="{{.Id}}" "$image_name" 2>/dev/null)
        local_image_id=$(docker inspect --format="{{.Id}}" "$image_name" 2>/dev/null)
        [ "$remote_image_id" != "$local_image_id" ]
    }

    getHosts() {
        run_ansible --mount-path $(pwd) \
        ansible \
            $1 \
            --inventory-file $inventory_file \
            --module-name ping \
            --list-hosts \
            $additional_ansible_args \
            | awk 'NR>1 {gsub(/\r/,""); print $1}'
    }

    loading_spinner() {
            local pid=$1
            local delay=0.1
            local spinstr='|/-\\'
            while kill -0 $pid 2>/dev/null; do
                local temp=${spinstr#?}
                printf " [%c]  " "$spinstr"
                local spinstr=$temp${spinstr%"$temp"}
                sleep $delay
                printf "\r\b\b\b\b\b\b"
            done
            printf "    \r\b\b\b\b"
    }

    transferDockerImage() {
        image_name="$1"
        host="$2"

        echo "${BOLD}${YELLOW}⚡️ Uploading Docker image '$image_name' to host '$host'. This could take a while...${RESET}"

        # Run the Docker save and SSH command in the background
        (docker save "$image_name" | gzip | ssh -p "$ssh_port" "$ssh_user@$host" docker load) &

        # Capture the PID of the background process
        pid=$!

        # Start the spinner
        loading_spinner $pid

        # Wait for the background process to finish
        wait $pid
        local status=$?

        # Check if the process succeeded
        if [ $status -ne 0 ]; then
            echo "${BOLD}${RED}Error: Failed to transfer Docker image.${RESET}"
            return $status
        else
            echo "${BOLD}${GREEN}✅ Docker image '$image_name' has been successfully uploaded to '$host'.${RESET}"
        fi
    }

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user|-u)
                ssh_user="$2"
                shift 2
                ;;
            --compose-file|-c)
                if [[ -n "$2" && "$2" != -* ]]; then
                    compose_files+=("$2")
                    shift 2
                else
                    echo "Error: '-c' option requires a Docker Compose file as argument."
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

    # Prepare SSH connection
    if [[ -n "$ssh_port" ]]; then
        ssh_port="$(get_ansible_variable "ssh_port")"
    fi

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

    # Prepare the Ansible run
    prepare_ansible_run

    # Build and transfer for each Dockerfile
    for file in Dockerfile*; do
        if [ "$file" == "Dockerfile" ]; then
            image_suffix="dockerfile"
        else
            # Extract the suffix from the Dockerfile name
            image_suffix="${file#Dockerfile}"
        fi
        image_tag="$(get_md5_hash "$file")"

        image_name="${image_prefix}/${image_suffix}:${image_tag}"

        # Build the Docker image
        echo "${BOLD}${BLUE}🐳 Building Docker image '$image_name' from '$file'...${RESET}"
        docker buildx build --platform "$build_platform" -t "$image_name" -f "$file" . --load
        if [ $? -eq 0 ]; then
            echo "${BOLD}${BLUE}📦 Successfully built '$image_name' from '$file'...${RESET}"
        else
            echo "${BOLD}${RED}❌ Failed to build '$image_name' from '$file'.${RESET}"
            exit 1
        fi

        # Transfer the image to the remote hosts
        for host in $(getHosts "$deployment_environment"); do
        if dockerImageNeedsUpdate "$image_name" "$host"; then
            transferDockerImage "$image_name" "$host"
        else
            echo "${BOLD}${GREEN}🚀 Docker image '$image_name' is up to date on host '$host'.${RESET}"
        fi
        done
    done

}