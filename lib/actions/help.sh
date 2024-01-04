#!/usr/bin/env bash
action_help(){
  echo -e "${BLUE}${BOLD}================== Spin Help Menu ==================${RESET}"

  echo -e "${GREEN}Available commands:${RESET}"
  for file in $SPIN_HOME/lib/actions/*.sh; do
    command=$(basename "$file" .sh)
    echo -e "${YELLOW}${BOLD}- $command${RESET}"
  done

  echo -e "${RED}Run '${BOLD}spin <command>${RESET}${RED}' to execute a command.${RESET}"
  
  echo -e "${GREEN}For detailed documentation, visit:${RESET} ${BOLD}https://serversideup.net/open-source/spin/docs${RESET}"
}