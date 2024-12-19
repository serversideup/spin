#!/bin/bash
#
# This installer was heavily inspired by talented devs of OhMyZSH https://github.com/ohmyzsh/ohmyzsh
#
# This script should be run via curl:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
# or via wget:
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
# or via fetch:
#   bash -c "$(fetch -o - https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh
#   bash install.sh
#
# You can tweak the install behavior by setting variables when running the script. For
# example, to change the path to the SPIN repository:
#   SPIN_HOME=~/.spin sh install.sh
#
# Respects the following environment variables:
#   SPIN_HOME - path to the Spin repository folder (default: $HOME/.spin)
#   REPO      - name of the GitHub repo to install from (default: serversideup/spin)
#   REMOTE    - full remote URL of the git repo to install (default: GitHub via HTTPS)
#   BRANCH    - branch to check out immediately after install (default: main)
#
#
# You can also pass some arguments to the install script to set some these options:
#   --beta: use the latest release (regardless of pre-release or stable)
# For example:
#   bash install.sh --beta
# or:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)" "" --beta
#

############################################################################################################
# Settings
###########################################################################################################

# set -x
set -e

# Default settings
SPIN_HOME=${SPIN_HOME:-$HOME/.spin}
SPIN_CACHE_DIR=${SPIN_CACHE_DIR:-$SPIN_HOME/cache}
REPO=${REPO:-serversideup/spin}
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-''}
TRACK=${TRACK:-stable}

############################################################################################################
# Environment Prep: Functions that get a bunch of information and prepare the terminal
############################################################################################################

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() {
    true
  }
else
  is_tty() {
    false
  }
fi

# This function uses the logic from supports-hyperlinks[1][2], which is
# made by Kat Marchán (@zkat) and licensed under the Apache License 2.0.
# [1] https://github.com/zkat/supports-hyperlinks
# [2] https://crates.io/crates/supports-hyperlinks
#
# Copyright (c) 2021 Kat Marchán
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
supports_hyperlinks() {
  # $FORCE_HYPERLINK must be set and be non-zero (this acts as a logic bypass)
  if [ -n "$FORCE_HYPERLINK" ]; then
    [ "$FORCE_HYPERLINK" != 0 ]
    return $?
  fi

  # If stdout is not a tty, it doesn't support hyperlinks
  is_tty || return 1

  # DomTerm terminal emulator (domterm.org)
  if [ -n "$DOMTERM" ]; then
    return 0
  fi

  # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
  if [ -n "$VTE_VERSION" ]; then
    [ $VTE_VERSION -ge 5000 ]
    return $?
  fi

  # If $TERM_PROGRAM is set, these terminals support hyperlinks
  case "$TERM_PROGRAM" in
  Hyper|iTerm.app|terminology|WezTerm) return 0 ;;
  esac

  # kitty supports hyperlinks
  if [ "$TERM" = xterm-kitty ]; then
    return 0
  fi

  # Windows Terminal or Konsole also support hyperlinks
  if [ -n "$WT_SESSION" ] || [ -n "$KONSOLE_VERSION" ]; then
    return 0
  fi

  return 1
}

fmt_link() {
  # $1: text, $2: url, $3: fallback mode
  if supports_hyperlinks; then
    printf '\033]8;;%s\a%s\033]8;;\a\n' "$2" "$1"
    return
  fi

  case "$3" in
  --text) printf '%s\n' "$1" ;;
  --url|*) fmt_underline "$2" ;;
  esac
}

fmt_underline() {
  is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
  printf '%sError: %s%s\n' "$BOLD$RED" "$*" "$RESET" >&2
}

setup_color() {
  # Only use colors if connected to a terminal
  if is_tty; then
    RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
    "
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
  else
    RAINBOW=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
  fi
}

############################################################################################################
# Functions for app functionality and tests
############################################################################################################

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

get_install_version() {
  if [ ! -z "$BRANCH" ]; then
    echo "$BRANCH"
    return 0
  fi
  if [ "$TRACK" = "beta" ]; then
    # Get the latest release (including pre-releases). We just want the 
    # absolute latest release, regardless of pre-release or stable
    curl --silent \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/serversideup/spin/releases" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/' | \
    head -n 1
  else
    # Get latest stable release
    curl --silent \
      -H 'Accept: application/vnd.github.v3.sha' \
      "https://api.github.com/repos/serversideup/spin/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
  fi
}

set_configuration_file() {
  mkdir -p "$SPIN_HOME/conf/"
  echo "TRACK=$TRACK" > "$SPIN_HOME/conf/spin.conf"
}

save_last_update_check_time() {
  date +"%s" > "$SPIN_CACHE_DIR/.spin-last-update"
}

setup_spin() {
  # Prevent the cloned repository from having insecure permissions. Failing to do
  # so causes compinit() calls to fail with "command not found: compdef" errors
  # for users with insecure umasks (e.g., "002", allowing group writability). Note
  # that this will be ignored under Cygwin by default, as Windows ACLs take
  # precedence over umasks except for filesystems mounted with option "noacl".
umask g-w,o-w

  command_exists git || {
    fmt_error "git is not installed"
    exit 1
  }

  SPIN_INSTALL_VERSION=$(get_install_version)

  echo "${BLUE}Cloning Spin \"$SPIN_INSTALL_VERSION\"...${RESET}"

  # Initialize an empty Git repository
  mkdir -p "$SPIN_HOME" > /dev/null 2>&1
  git init "$SPIN_HOME" > /dev/null 2>&1
  cd "$SPIN_HOME"

  # Add the remote repository
  git remote add -f origin "$REMOTE" > /dev/null 2>&1

  # Set explicit endings
  git config core.eol lf
  git config core.autocrlf false

  # Enable sparse checkout and configure it
  git config core.sparseCheckout true > /dev/null 2>&1
  echo "/*" > .git/info/sparse-checkout
  echo "!/docs" >> .git/info/sparse-checkout
  echo "!/.github" >> .git/info/sparse-checkout
  echo "!/composer.json" >> .git/info/sparse-checkout
  echo "!/package.json" >> .git/info/sparse-checkout
  echo "!/.npmignore" >> .git/info/sparse-checkout

  # Fetch and checkout the specific branch with depth 1
  git fetch --depth=1 origin "$SPIN_INSTALL_VERSION" > /dev/null 2>&1
  git checkout FETCH_HEAD > /dev/null 2>&1

  # Additional setup steps
  set_configuration_file
  save_last_update_check_time
  prompt_to_add_path

  echo #Empty line
}

prompt_to_add_path() {
    # Detect the shell type
    shell_type=$(basename "$SHELL")

    # Determine which file to modify based on the shell type
    case "$shell_type" in
        bash)
            file=~/.bash_profile
            ;;
        zsh)
            file=~/.zshrc
            ;;
        *)
            echo "${RED}${BOLD}❌ Unable to detect shell type.${RESET}"
            echo "To add 'spin' to your path manually, add the following line to your shell's profile file:"
            echo 'export PATH="'${SPIN_HOME}'/bin:$PATH"'
            return 1
            ;;
    esac

    # Check if SPIN_HOME is set to the default value
    if [ "$SPIN_HOME" = "$HOME/.spin" ]; then
        path_value='$HOME/.spin'
    else
        path_value=$SPIN_HOME
    fi

    # Dynamically build the grep pattern
    grep_pattern=$(echo 'export PATH="'$path_value'/bin:$PATH"')

    # Check if the path is already in the file
    if ! grep -qF "$grep_pattern" "$file"; then
        echo "Spin detected your shell environment:"
        echo "👉 Shell Type: \"$shell_type\"."
        echo "👉 Shell Profile: \"$file\"."

        if [ -z "$set_path_automatically" ]; then
            read -n 1 -p "${BOLD}${YELLOW}Would you like Spin to add itself to your PATH? [y/N] ${RESET}" response
            echo # Empty line

            if [[ "$response" =~ ^[Yy]$ ]]; then
                set_path_automatically=1
            else
                set_path_automatically=0
            fi
        fi
    else
        echo "✅ Correct PATH detected in \"$file\"."
    fi

    if [ "$set_path_automatically" = 1 ]; then
        echo "👉 Adding Spin to your PATH in \"$file\"."
        echo 'export PATH="'$path_value'/bin:$PATH"' >> "$file"
    fi
}

# shellcheck disable=SC2183  # printf string has more %s than arguments ($RAINBOW expands to multiple arguments)
print_success() {
    printf '%s      ___     %s      ___   %s            %s      ___     %s\n'      $RAINBOW $RESET
    printf '%s     /  /\    %s     /  /\  %s    ___     %s     /__/\    %s\n'      $RAINBOW $RESET
    printf '%s    /  /:/_   %s    /  /::\ %s   /  /\    %s     \  \:\   %s\n'      $RAINBOW $RESET
    printf '%s   /  /:/ /\  %s   /  /:/\:\%s  /  /:/    %s      \  \:\  %s\n'      $RAINBOW $RESET
    printf '%s  /  /:/ /::\ %s  /  /:/~/:/%s /__/::\    %s  _____\__\:\ %s\n'      $RAINBOW $RESET
    printf '%s /__/:/ /:/\:\%s /__/:/ /:/ %s \__\/\:\__ %s /__/::::::::\%s\n'      $RAINBOW $RESET
    printf '%s \  \:\/:/~/:/%s \  \:\/:/  %s    \  \:\/\%s \  \:\~~\~~\/%s\n'      $RAINBOW $RESET
    printf '%s  \  \::/ /:/ %s  \  \::/   %s     \__\::/%s  \  \:\  ~~~ %s\n'      $RAINBOW $RESET
    printf '%s   \__\/ /:/  %s   \  \:\   %s     /__/:/ %s   \  \:\     %s\n'      $RAINBOW $RESET
    printf '%s     /__/:/   %s    \  \:\  %s     \__\/  %s    \  \:\    %s\n'      $RAINBOW $RESET
    printf '%s     \__\/    %s     \__\/  %s            %s     \__\/    %s\n'      $RAINBOW $RESET
    printf '\n'
    printf "%s %s %s\n" "${BOLD}${GREEN}✅ Spin \"$SPIN_INSTALL_VERSION\" installed!${RESET} Check out the documentation to get started."
    printf '\n'
    printf '%s\n' "• See what \"spin\" is capable of: $(fmt_link "Read the Docs" https://serversideup.net/open-source/spin/)"
    printf '%s\n' "• Get latest news and updates by follow on Twitter: $(fmt_link @serversideup https://twitter.com/serversideup)"
    printf '%s\n' "• Meet friends and get help on our Discord community: $(fmt_link "Join our Discord Community" https://serversideup.net/discord)"
    printf '%s\n' "• Get sweet perks, exclusive access, and professional support: $(fmt_link "Become a sponsor" https://serversideup.net/sponsor)"
    if [ "$set_path_automatically" = 1 ]; then
        printf '\n'
        printf '%s\n'"${BOLD}${YELLOW}Spin was automatically added to your path, but you may need to close your terminal and restart it to start using it.${RESET}"
        printf '%s\n'"Or you can run $(fmt_code "source $file") to reload your profile."
    elif [ "$set_path_automatically" = 0 ]; then
        printf '\n'
        printf '%s\n'"${BOLD}${YELLOW}You will need to add \"spin\" to your path manually.${RESET}"
        printf '%s\n'"To do so, add the following line to your shell's profile file:"
        printf '%s\n'"$(fmt_code 'export PATH="'$path_value'/bin:$PATH"')"
        printf '%s\n'"Then, restart your terminal."
    fi
    printf '%s\n' $RESET
}

main() {
  # Parse arguments passed to install script
  while [ $# -gt 0 ]; do
    case $1 in
      --beta) TRACK=beta ;;
      --force) set_path_automatically=1 ;;
      *)

    esac
    shift
  done
  setup_color
  setup_spin
  print_success
}

main "$@"