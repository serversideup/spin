#!/usr/bin/env bash
action_pull() {
    $COMPOSE_CMD pull
    update_last_pull_timestamp
}