#!/usr/bin/env bash
action_up() {
  docker_pull_check "$@"

  filter_out_spin_arguments "$@"
  local args=("${SPIN_FILTERED_ARGS[@]}")

  $COMPOSE_CMD up --remove-orphans "${args[@]}"
}