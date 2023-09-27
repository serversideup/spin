#!/usr/bin/env bash
action_kill(){
  if [[ $(docker ps --format '{{.Names}}' 2>/dev/null) ]]; then
    read -n 1 -r -p "🚨 You're about to kill all running containers. Are you sure you want to do this? (Y) "
    echo    # Move to a new line

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelling... Nothing with Docker was touched 😅"
        exit 1
    fi

    echo "Killing containers..."
    docker kill $(docker ps -q)
  else
    echo "👉 No containers are running."
  fi
}