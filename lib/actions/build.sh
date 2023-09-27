#!/usr/bin/env bash
action_build() {
  # Build the containers with `docker-compose`
  $COMPOSE_CMD build "$@"
}