#!/usr/bin/env bash
action_deploy(){
  deployment_environment="$1"
  additional_ansible_args=""
  remote_user_arg=""
  remote_user="${SPIIN_REMOTE_SSH_USER:-$(whoami)}"
  remote_ssh_port="${SPIN_REMOTE_SSH_PORT:-22}"
  inventory_file=".spin-inventory.ini"
  image_prefix="${SPIN_LOCAL_IMAGE_PREFIX:-local.docker}"
  export SPIN_DOCKER_BUILD_TIMESTAMP=$(date +%s)

  # Process arguments
  while [[ "$#" -gt 1 ]]; do
      case "$1" in
          --user|-u)
              remote_user="$2"
              remote_user_arg="--ask-become-pass --extra-vars ansible_user=$remote_user"
              shift 2
              ;;
      esac
  done

  # Check if vault password exists
  if [[ -f .vault-password ]]; then
      additional_ansible_args="--vault-password-file .vault-password"
  elif is_encrypted_with_ansible_vault "$inventory_file"; then
      additional_ansible_args="--ask-vault-password"
  fi

  # Validate environment is passed
  if [ -z "$deployment_environment" ]; then
    printf "${BOLD}${YELLOW}👉 You must pass an environment to deploy to (production, staging, etc)${RESET}"
    echo
    exit 1
  fi

  buildDockerImages() {
      # Check if any Dockerfiles exist
      if [ -z "$(ls Dockerfile* 2>/dev/null)" ]; then
          printf "${BOLD}${YELLOW}❌ No Dockerfiles found in this directory. Be sure to run \"spin deploy\" in your project root.${RESET}\n"
          exit 1
      fi

      # Loop through all files matching the pattern "Dockerfile*"
      for file in Dockerfile*; do
          # Determine the image name based on the file name
          if [ "$file" == "Dockerfile" ]; then
              image_suffix="dockerfile"
          else
              # Extract the part after "Dockerfile." for the image name
              image_suffix="${file#Dockerfile.}"
          fi

          image_name="$image_prefix/$image_suffix:$SPIN_DOCKER_BUILD_TIMESTAMP"
          
          # Assuming the context is the current directory, modify if needed
          printf "${BOLD}${BLUE}🐳 Building Docker image '$image_name' from '$file'...${RESET}\n"
          docker buildx build --platform linux/amd64 -f "$file" -t "$image_name" .  --load
          if [ $? -eq 0 ]; then
              echo "Successfully built $image_name from $file"
              printf "${BOLD}${BLUE}📦 Successfully built '$image_name' from '$file'...${RESET}\n"
          else
              printf "${BOLD}${RED}❌ Failed to build '$image_name' from '$file'...${RESET}\n"
          fi

          # Transfer the image to the remote hosts
          for host in $(getHosts "$deployment_environment"); do
            if dockerImageNeedsUpdate "$image_name" "$host"; then
              transferDockerImage "$image_name" "$host"
            else
              printf "${BOLD}${GREEN}🚀 Docker image '$image_name' is up to date on host '$host'.${RESET}\n"
            fi
          done
      done
  }

  deploySwarmStack() {
    # Install the required Ansible roles
    # run_ansible ansible-galaxy collection install serversideup.spin --upgrade

    # # Run the playbook
    # run_ansible ansible-playbook serversideup.spin.deploy \
    #     --inventory ./$inventory_file \
    #     --extra-vars @./.spin.yml \
    #     $remote_user_arg \
    #     $additional_ansible_args
    echo "none"
    
  }

  dockerImageNeedsUpdate() {
    image_name="$1"
    host="$2"
    remote_image_id=$(ssh -p "$remote_ssh_port" "$remote_user@$host" docker inspect --format="{{.Id}}" "$image_name" 2>/dev/null)
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

  transferDockerImage() {
    image_name="$1"
    host="$2"
    printf "${BOLD}${YELLOW}⚡️ Uploading Docker image '$image_name' to host '$host'. This could take a while...${RESET}\n"
    docker save "$image_name" | gzip | ssh -p "$remote_ssh_port" "$remote_user@$host" docker load

    docker --log-level debug -H "ssh://$remote_user@$host:$remote_ssh_port" \
          stack deploy --with-registry-auth \
          -c docker-compose.yml -c docker-compose.prod.yml \
          $deployment_environment \
          --prune
  }

  ##############################
  # Main deploy action
  ##############################
  buildDockerImages "$@"
  # deploySwarmStack
}