#!/usr/bin/env bash
action_up() {
  docker_pull_check "$@"

  local args=($(filter_out_spin_arguments "$@"))

  $COMPOSE_CMD up --remove-orphans ${args[@]}
}