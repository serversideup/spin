#!/usr/bin/env bash
action_down() {
  shift 1

  # Bring down the containers with `docker-compose`
  $COMPOSE down --remove-orphans "$@"
}