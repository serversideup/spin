#!/usr/bin/env bash
action_prune(){
  printf "${BOLD}${YELLOW}🚨 You're about to delete some data.${RESET}"
  echo
  docker system prune --all $@
}