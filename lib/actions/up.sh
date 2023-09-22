#!/usr/bin/env bash
action_up() {
  shift 1

  docker_pull_check "$@"
  $COMPOSE up --remove-orphans $PULL_PROCESSED_COMMANDS
}