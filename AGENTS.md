# AI Agent Guidelines for Spin Source Code

You are an expert in Bash scripting, Docker, and Ansible. You possess deep knowledge of best practices and performance optimization techniques for writing Bash and Ansible code. You understand the challenges of cross-platform shell scripting and prioritize compatibility and reliability.

## Project Context

**Spin** is a bash utility that improves the developer experience for teams using Docker. It's a wrapper script that helps users:
- Replicate any environment on any machine (MacOS, Windows/WSL2, Linux)
- Provision and configure production servers
- Deploy applications using Docker Compose and Docker Swarm
- Maintain infrastructure with Ansible

Spin is framework-agnostic and works with any application that can be containerized.

## Project Structure

```
bin/
├── spin                    # Main executable entry point

lib/
├── functions.sh            # Shared utility functions
└── actions/                # Individual command implementations
    ├── up.sh               # spin up
    ├── deploy.sh           # spin deploy
    ├── provision.sh        # spin provision
    └── ...                 # One file per command

tools/
├── install.sh              # Installation script
└── upgrade.sh              # Upgrade script

conf/
└── spin.example.conf       # Example configuration

cache/                      # Runtime cache storage

docs/                       # Documentation site (separate AGENTS.md)
```

## Code Style and Structure

### Bash Compatibility Requirements

**Critical**: All bash code must be compatible with:
- **Bash v3.2+** (MacOS ships with Bash 3.2 due to licensing)
- **Linux** (Ubuntu, Debian, CentOS, etc.)
- **WSL2** (Windows Subsystem for Linux)

This means:
- No associative arrays (`declare -A`) - use alternative patterns
- No `mapfile` or `readarray` - use `while read` loops
- No `${var,,}` or `${var^^}` for case conversion - use `tr` instead
- No `|&` for piping stderr - use `2>&1 |`
- No `[[ ]]` with regex `=~` using stored patterns - inline patterns only
- Test with `bash --posix` when possible

### Function Naming Conventions

```bash
# Action functions (called from bin/spin)
action_up() { ... }
action_deploy() { ... }
action_provision() { ... }

# Utility functions (in lib/functions.sh)
check_if_docker_is_running() { ... }
export_compose_file_variable() { ... }
send_to_upgrade_script() { ... }
```

- Use `snake_case` for all function names
- Prefix action entry points with `action_`
- Use descriptive, verb-based names

### Variable Naming

```bash
# Environment variables (exported, user-configurable)
SPIN_ENV=${SPIN_ENV:-dev}
SPIN_DEBUG=${SPIN_DEBUG:-false}
SPIN_USER_ID=${SPIN_USER_ID:-$(id -u)}

# Local variables
local args=()
local response=""
local cmd="$1"

# Always provide defaults for user-configurable variables
SPIN_PHP_IMAGE=${SPIN_PHP_IMAGE:-"serversideup/php:cli"}
```

- Use `UPPER_SNAKE_CASE` for environment variables
- Use `lower_snake_case` for local variables
- Always use `local` for function-scoped variables
- Provide sensible defaults with `${VAR:-default}`

### Cross-Platform Patterns

Handle OS differences explicitly:

```bash
# Example: base64 encoding differs between MacOS and Linux
if [[ "$(uname -s)" == "Darwin" ]]; then
    base64 -b 0 -i "$input"
else
    base64 -w 0 "$input"
fi
```

Common differences to handle:
- `base64` flags (`-b 0` vs `-w 0`)
- `sed` in-place editing (`-i ''` vs `-i`)
- `date` formatting options
- `grep` extended regex (`-E` is portable, avoid `-P`)
- `readlink -f` (not available on MacOS - use alternatives)

### Error Handling

```bash
# Use set -e at script entry points
set -e

# For specific commands that may fail, handle explicitly
if ! docker info > /dev/null 2>&1; then
    printf "${BOLD}${RED}❌ Docker is not running.${RESET} "
    exit 1
fi

# Use meaningful exit codes
exit 0  # Success
exit 1  # General error
exit 127  # Command not found
```

### Output and User Communication

```bash
# Color definitions (from setup_color function)
# Use these for consistent output
printf "${BOLD}${GREEN}✅ Success${RESET}\n"
printf "${BOLD}${RED}❌ Error${RESET}\n"
printf "${BOLD}${YELLOW}⚠️ Warning${RESET}\n"

# Always provide context in error messages
echo "\"$spin_action\" is not a valid command."

# Use printf for complex formatting, echo for simple messages
```

### Docker Integration Patterns

```bash
# Use COMPOSE_CMD variable (allows override)
export COMPOSE_CMD=${COMPOSE_CMD:-"docker compose"}

# Set COMPOSE_FILE for multi-file configurations
export COMPOSE_FILE="docker-compose.yml:docker-compose.${SPIN_ENV}.yml"

# Run Docker with proper user context
docker run --rm \
    -u "${SPIN_USER_ID}:${SPIN_GROUP_ID}" \
    -v "$(pwd):/app" \
    -w /app \
    "$SPIN_PHP_IMAGE" "$@"
```

### Adding New Commands

1. Create a new file in `lib/actions/` named `commandname.sh`
2. Define the entry function as `action_commandname()`
3. Add the case statement in `bin/spin`
4. Document the command in `docs/content/docs/9.command-reference/`

```bash
# lib/actions/example.sh
#!/usr/bin/env bash
action_example() {
    local args=($(filter_out_spin_arguments "$@"))
    
    # Implementation here
    echo "Running example command"
}
```

```bash
# Add to bin/spin case statement
example)
    source "$SPIN_HOME/lib/actions/example.sh"
    action_example "$@"
;;
```

## Dependencies and Constraints

### No Additional Dependencies

Spin must work without requiring users to install anything beyond Docker:
- No Ruby, Python, or Node.js dependencies for the CLI itself
- No upgraded Bash requirement (must work with v3.2)
- No GNU coreutils requirement on MacOS
- Use Docker images to run tools (Ansible, GitHub CLI, etc.)

```bash
# Example: Running Ansible via Docker instead of local install
docker run --rm \
    -v "$(pwd):/app" \
    "$SPIN_ANSIBLE_IMAGE" ansible-playbook playbook.yml
```

### Docker Images Used

Spin uses these Docker images for tooling:
- `serversideup/ansible-core` - For running Ansible playbooks
- `serversideup/github-cli` - For GitHub CLI operations
- `serversideup/php:cli` - For PHP-related operations
- `node:20` - For Node.js operations

## Testing Considerations

When making changes:
1. Test on MacOS (Bash 3.2)
2. Test on Linux (Ubuntu/Debian preferred)
3. Test on WSL2 if possible
4. Verify Docker commands work with both Docker Desktop and native Docker
5. Test with `SPIN_DEBUG=true` to see command execution

```bash
# Enable debug mode
SPIN_DEBUG=true spin up

# Test specific environment
SPIN_ENV=production spin deploy production
```

## Common Patterns in Codebase

### Argument Filtering

```bash
# Remove Spin-specific arguments before passing to Docker
local args=($(filter_out_spin_arguments "$@"))
$COMPOSE_CMD up ${args[@]}
```

### Cache Management

```bash
# Check if action needs update based on cache file
if needs_update ".spin-last-update" "$AUTO_UPDATE_INTERVAL_IN_DAYS"; then
    # Perform update check
fi

# Save timestamp to cache
save_current_time_to_cache_file ".spin-last-update"
```

### User Prompts

```bash
# Interactive prompt with default
read -n 1 -r -p "${BOLD}${YELLOW}[spin] Would you like to continue? [Y/n]${RESET} " response
case "$response" in
    [yY$'\n'])
        # Yes action
        ;;
    *)
        # No action
        ;;
esac
```

## When to Ask Questions

Don't assume when:
- Changes affect cross-platform compatibility
- New dependencies would be introduced
- Docker command behavior might differ across versions
- Changes could break existing user workflows
- Ansible playbook changes could affect server security

## Related Projects

- [Spin Ansible Collection](https://github.com/serversideup/ansible-collection-spin) - Server provisioning
- [serversideup/php](https://github.com/serversideup/docker-php) - PHP Docker images
- [Docker Build Action](https://github.com/serversideup/docker-build-action) - GitHub Actions
- [Docker Swarm Deploy Action](https://github.com/serversideup/docker-swarm-deploy-github-action) - GitHub Actions

## Remember

- **Compatibility first**: Always prioritize Bash 3.2 and cross-platform support
- **No dependencies**: Users should only need Docker installed
- **Transparent wrapping**: Spin follows Docker/Compose syntax - don't invent new DSLs
- **Fail gracefully**: Provide helpful error messages when things go wrong
- **Open source mindset**: Write code that others can understand, modify, and contribute to

Your goal is to maintain Spin as a reliable, cross-platform tool that makes Docker workflows easier for developers.
