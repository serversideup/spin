#!/usr/bin/env bash
action_up() {
  docker_pull_check "$@"

  local args=($(filter_out_spin_arguments "$@"))

  # Check if 'set -x' is enabled
  if [[ $- == *x* ]]; then
      # If 'set -x' is enabled, echo the COMPOSE_FILE variable
      echo "COMPOSE_FILE: $COMPOSE_FILE"
  fi

  $COMPOSE_CMD up --remove-orphans ${args[@]}
}