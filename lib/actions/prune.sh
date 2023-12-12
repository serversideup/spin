#!/usr/bin/env bash
action_prune(){
  echo "${BOLD}${YELLOW}🚨 You're about to delete some data.${RESET}"
  docker system prune --all $@
  echo "${BOLD}${GREEN}✅ Docker cache cleared.${RESET}"
  rm -rf $SPIN_CACHE_DIR/.spin*
  echo "${BOLD}${GREEN}✅ Spin cache cleared.${RESET}"
}