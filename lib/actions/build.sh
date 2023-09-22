#!/usr/bin/env bash
action_build() {
  shift 1

  # Build the containers with `docker-compose`
  $COMPOSE build "$@"
}