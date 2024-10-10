#!/usr/bin/env bash
action_prune(){
  echo "${BOLD}${YELLOW}🚨 You're about to delete some data.${RESET}"
  docker system prune --all $@
  echo "${BOLD}${GREEN}✅ Docker cache cleared.${RESET}"

  if [ -z "$SPIN_CACHE_DIR" ]; then
    echo "Error: SPIN_CACHE_DIR is not set"
    exit 1
  fi

  if compgen -G "$SPIN_CACHE_DIR/.spin*" > /dev/null; then
    rm -rf "$SPIN_CACHE_DIR"/.spin*
    echo "${BOLD}${GREEN}✅ Spin update cache cleared.${RESET}"
  fi

  if [ -d "$SPIN_CACHE_DIR/collections/" ]; then
    rm -rf $SPIN_CACHE_DIR/collections/
    echo "${BOLD}${GREEN}✅ Spin Ansible Collections cache cleared.${RESET}"
  fi

  if [ -d "$SPIN_CACHE_DIR/registry/" ]; then
    rm -rf $SPIN_CACHE_DIR/registry/
    echo "${BOLD}${GREEN}✅ Spin Docker Registry cache cleared.${RESET}"
  fi  
}