#!/usr/bin/env bash
action_down() {
  local args=($(filter_out_spin_arguments "$@"))

  $COMPOSE_CMD down --remove-orphans "${args[@]}"
}