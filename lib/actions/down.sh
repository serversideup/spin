#!/usr/bin/env bash
action_down() {
  filter_out_spin_arguments "$@"
  local args=("${SPIN_FILTERED_ARGS[@]}")

  $COMPOSE_CMD down --remove-orphans "${args[@]}"
}