#!/usr/bin/env bash
action_run(){
  docker_pull_check "$@"

  local args=($(filter_out_spin_arguments "$@"))

  # Run Docker Compose without dependencies. Ensure automations and S6 logging are disabled
  $COMPOSE_CMD run --remove-orphans --no-deps --rm \
    -e "LOG_LEVEL=off" -e "LOG_LEVEL=off" \
    "${args[@]}"
}