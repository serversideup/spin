#!/usr/bin/env bash
action_php(){
  docker_pull_check "$@"

  local args=($(filter_out_spin_arguments "$@"))

  # Run Docker Compose without dependencies. Ensure automations and S6 logging are disabled
  $COMPOSE_CMD run --remove-orphans --no-deps --rm \
    --entrypoint '' \
    -e "LOG_LEVEL=off" \
    --user "$SPIN_DEFAULT_PHP_USER:$SPIN_GROUP_ID" \
    $SPIN_DEFAULT_PHP_SERVICE_NAME \
    "${args[@]}"
}