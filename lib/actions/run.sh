#!/usr/bin/env bash
action_run(){
  docker_pull_check "$@"

  local args=($(filter_out_spin_arguments "$@"))

  # Run Docker Compose without dependencies. Ensure automations and S6 logging are disabled
  $COMPOSE_CMD run -e "S6_VERBOSITY=0" -e "SHOW_WELCOME_MESSAGE=false" --remove-orphans --no-deps --rm \
    "${args[@]}"
}