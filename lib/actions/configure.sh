#!/usr/bin/env bash

#################################
# Main Action Handler
#################################
action_configure() {
  case "$1" in
    gha)
      shift
      configure_gha "$@"
      ;;
    *)
      show_usage "$1"
      exit 1
      ;;
  esac

}

#################################
# Helper Functions
#################################
configure_gha() {
    if [ $# -eq 0 ]; then
        echo "${BOLD}${RED}❌ No environment specified${RESET}"
        echo "Usage: spin configure gha <environment>"
        echo "Example: spin configure gha production"
        return 1
    fi

    local gha_environment="$1"
    shift # Remove the first argument
    local gha_environment_uppercase=$(echo "$gha_environment" | tr '[:lower:]' '[:upper:]')
    
    validate_repository_setup || exit 1
    
    local environment_file
    environment_file=$(validate_environment_file "$gha_environment") || exit 1

    gh_set_env --base64 --variable "${gha_environment_uppercase}_ENV_FILE_BASE64" --file "$environment_file"

    configure_gha_deployment_key "$@"
    configure_gha_authorized_keys

}

configure_gha_deployment_key() {
  local inventory_file="${SPIN_INVENTORY_FILE:-"/etc/ansible/collections/ansible_collections/serversideup/spin/plugins/inventory/spin-dynamic-inventory.sh"}"
  local infrastructure_folder=".infrastructure"

  if [ ! -d "$infrastructure_folder" ]; then
    echo "${BOLD}${RED}❌ Infrastructure folder not found${RESET}"
    echo "Please ensure you're in the root of your project."
    return 1
  fi

  if [ ! -d "$infrastructure_folder/deploy-keys" ] || [ ! -f "$infrastructure_folder/deploy-keys/.gitignore" ]; then
    mkdir -p "$infrastructure_folder/deploy-keys"
    echo "*" > "$infrastructure_folder/deploy-keys/.gitignore"
    echo "!.gitignore" >> "$infrastructure_folder/deploy-keys/.gitignore"
  fi

  if [ ! -f "$infrastructure_folder/deploy-keys/id_ed25519_deploy" ]; then
    echo "🔑 Generating deployment key"
    ssh-keygen -t ed25519 -C "deploy-key" -f "$infrastructure_folder/deploy-keys/id_ed25519_deploy" -N ""
    echo "${BOLD}${GREEN}✅ Deployment key generated${RESET}"
  else
    echo "🔑 Using existing deployment key found at \"$infrastructure_folder/deploy-keys/id_ed25519_deploy\""
  fi

  # Read the public key content
  local deploy_public_key
  deploy_public_key=$(cat "$infrastructure_folder/deploy-keys/id_ed25519_deploy.pub")

  echo "🔑 Adding deployment key to GitHub repository"
  gh_set_env --variable "SSH_DEPLOY_PRIVATE_KEY" --file "$infrastructure_folder/deploy-keys/id_ed25519_deploy"

  echo "🔐 Adding deployment key to servers"
  prepare_ansible_args "$@"
  run_ansible --allow-ssh --mount-path "$(pwd)" \
        ansible-playbook serversideup.spin.update_deploy_key \
        --inventory "$inventory_file" \
        --extra-vars @./.spin.yml \
        --extra-vars "deploy_public_key='$deploy_public_key'" \
        "${SPIN_ANSIBLE_ARGS[@]}" \
        "${SPIN_UNPROCESSED_ARGS[@]}"
  
  echo "${BOLD}${GREEN}✅ Deployment key added to servers${RESET}"
}

configure_gha_authorized_keys() {
  echo "🔑 Gathering authorized keys for sudo users"
  local authorized_keys
  authorized_keys=$(run_ansible --minimal-output --mount-path "$(pwd)" \
    ansible-playbook serversideup.spin.get_sudo_keys \
    --extra-vars @./.spin.yml \
    | sed -n 's/.*"msg": "\(.*\)".*/\1/p' \
    | sed 's/\\\\n/\n/g')  # Handle the double escaped newlines

  echo "🔑 Adding authorized keys to GitHub repository"
  echo "$authorized_keys"

  # Add the authorized keys to GitHub secrets
  gh_set_env --variable "AUTHORIZED_KEYS" --value "$authorized_keys"
  
}

gh_set_env() {
  local base64_encode=false
  local variable=""
  local file=""
  local value=""

  # Parse arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --base64)
        base64_encode=true
        shift
        ;;
      --variable)
        variable="$2"
        shift 2
        ;;
      --file)
        file="$2"
        shift 2
        ;;
      --value)
        value="$2"
        shift 2
        ;;
      *)
        echo "${BOLD}${RED}❌ Invalid argument: $1${RESET}"
        return 1
        ;;
    esac
  done

  # Validate required arguments
  if [ -z "$variable" ] || { [ -z "$file" ] && [ -z "$value" ]; }; then
    echo "${BOLD}${RED}❌ Missing required arguments. Need --variable and either --file or --value.${RESET}"
    return 1
  fi

  if [ -n "$file" ] && [ -n "$value" ]; then
    echo "${BOLD}${RED}❌ Cannot specify both --file and --value.${RESET}"
    return 1
  fi

  # Get content from either file or value
  local content
  if [ -n "$file" ]; then
    if [ "$base64_encode" = true ]; then
      content=$(base64_encode "$file")
    else
      content=$(<"$file")
    fi
  else
    if [ "$base64_encode" = true ]; then
      content=$(echo -n "$value" | base64_encode -)
    else
      content="$value"
    fi
  fi

  # Set the secret using the gh CLI
  echo "$content" | run_gh secret set "$variable"

  echo "${BOLD}${GREEN}✅ Successfully set $variable secret for GitHub Actions${RESET}"
}

is_gh_cli_authenticated() {
  run_gh auth status >/dev/null 2>&1
}

is_github_repository() {
  run_gh repo view --json name >/dev/null 2>&1
}

show_usage() {
  echo "${BOLD}${RED}❌ Invalid command: $1${RESET}"
  echo
  echo "Usage: spin configure <command>"
  echo
  echo "Commands:"
  echo "  gha <environment>    Configure GitHub Actions settings for specified environment"
}

repository_exists() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

validate_environment_file() {
  local gha_environment="$1"
  local env_file=".env.$gha_environment"
  
  if [ -f "$env_file" ]; then
    echo "$env_file"  # Return the path if file exists
    return 0
  else
    echo "${BOLD}${RED}❌ Environment file not found ($env_file)${RESET}" >&2
    echo "Please ensure you have an environment variable file for the \"$gha_environment\" environment." >&2
    echo "Create a file called $env_file and add your environment variables to it." >&2
    echo "You can also change the environment by running \`spin configure gha <environment>\`." >&2
    return 1
  fi
}

validate_repository_setup() {
  if ! repository_exists; then
    echo "${BOLD}${RED}❌ Repository not detected.${RESET}"
    echo "Please ensure you're in the root of your project. If you need to create a repository, run \`git init\` then \`spin gh repo create\` to create one."
    return 1
  fi

  if ! is_gh_cli_authenticated; then
    echo "${BOLD}${RED}❌ GitHub CLI is not authenticated${RESET}"
    echo
    echo "Please authenticate with GitHub CLI by running \`spin gh auth login\`"
    return 1
  fi

  if ! is_github_repository; then
    echo "${BOLD}${RED}❌ Repository is not connected to GitHub.${RESET}"
    echo "This project must be connected to a GitHub repository to use GitHub Actions."
    echo "Add a GitHub remote or run \`spin gh repo create\` to create a GitHub repository."
    return 1
  fi

  return 0
}