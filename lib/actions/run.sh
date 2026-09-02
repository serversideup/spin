#!/usr/bin/env bash
action_run(){
  docker_pull_check "$@"

  # Dependencies are skipped by default to keep one-off commands fast, but
  # commands like test suites need the rest of the stack running.
  local dependency_args=("--no-deps")
  for arg in "$@"; do
    if [[ "$arg" == "--with-deps" ]]; then
      dependency_args=()
      break
    fi
  done

  filter_out_spin_arguments "$@"
  local args=("${SPIN_FILTERED_ARGS[@]}")

  # Ensure automations and S6 logging are disabled
  $COMPOSE_CMD run -e "S6_VERBOSITY=0" -e "SHOW_WELCOME_MESSAGE=false" --remove-orphans "${dependency_args[@]}" --rm \
    "${args[@]}"
}
