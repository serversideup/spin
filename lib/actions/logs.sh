#!/usr/bin/env bash
action_logs(){
  shift 1

  $COMPOSE logs "$@"
}