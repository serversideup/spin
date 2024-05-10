#!/usr/bin/env bash
action_new() {
  if [ $# -lt 1 ]; then
    echo "${BOLD}${YELLOW}🤔 You didn't pass \"spin new\" any arguments. Run \"spin help\" if you want to see the documentation.${RESET}"
    exit 1
  fi

  # When we call the `install.sh` script on a template,
  # set the SPIN_ACTION to "new"
  SPIN_ACTION="new"
  export SPIN_ACTION

  action_init "$@"
}
