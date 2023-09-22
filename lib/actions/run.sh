#!/usr/bin/env bash
action_run(){
  shift 1

  docker_pull_check "$@"

  # Run Docker Compose without dependencies. Ensure automations and S6 logging are disabled
    $COMPOSE run --no-deps --rm \
      -e "AUTORUN_ENABLED=false" \
      -e "S6_LOGGING=1" \
      $PULL_PROCESSED_COMMANDS

}