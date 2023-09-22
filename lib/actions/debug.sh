#!/usr/bin/env bash
action_debug(){
  
  print_version

  # Show operating system version
  printf "\n${BOLD}${YELLOW}Operating System Version:${RESET} \n"
  case "$(uname -s)" in
      Linux*)     cat /etc/os-release;;
      Darwin*)    sw_vers;;
      *)          echo "This operating system is not supported." && exit 2
  esac
  printf "\n"
  
  # Show docker version
  printf "${BOLD}${BLUE}Docker Info:${RESET} \n"
  printf "$(docker info)\n"
  
}