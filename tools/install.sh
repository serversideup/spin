#!/bin/sh
#
# This installer was heavily inspired by talented devs of OhMyZSH https://github.com/ohmyzsh/ohmyzsh
#
# This script should be run via curl:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
# or via wget:
#   sh -c "$(wget -qO- https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
# or via fetch:
#   sh -c "$(fetch -o - https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh
#   sh install.sh
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
#   --beta: use the latest pre-release
# For example:
#   sh install.sh --beta
# or:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/serversideup/spin/main/tools/install.sh)" --beta
#

############################################################################################################
# Settings
###########################################################################################################

# set -o xtrace
set -e

# Default settings
SPIN_HOME=${SPIN_HOME:-~/.spin}
REPO=${REPO:-serversideup/spin}
REMOTE=${REMOTE:-https://github.com/${REPO}.git}
BRANCH=${BRANCH:-main}

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

get_latest_release(){
  if [ $TRACK == "beta" ]; then
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

set_configuration_file(){
  mkdir -p $SPIN_HOME/conf/
  echo "TRACK=$TRACK" > $SPIN_HOME/conf/spin.conf
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

  local latest_release
  latest_release=$(get_latest_release)

  echo "${BLUE}Cloning Spin...${RESET}"

  git clone -c core.eol=lf -c core.autocrlf=false \
    -c fsck.zeroPaddedFilemode=ignore \
    -c fetch.fsck.zeroPaddedFilemode=ignore \
    -c receive.fsck.zeroPaddedFilemode=ignore \
    -c advice.detachedHead=false \
    -c spin.remote=origin \
    -c spin.branch="$BRANCH" \
    --depth=1 --branch "$latest_release" "$REMOTE" "$SPIN_HOME" || {
    fmt_error "git clone of spin repo failed"
    exit 1
  }

  set_track_lock_file

  echo #Empty line
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
    printf "%s %s %s\n" "${BOLD}${GREEN}✅ You are now ready to rock!${RESET} Check out the documentation to get started."
    printf '\n'
    printf '%s\n' "• Docs: $(fmt_link "Documentation" https://serversideup.net/open-source/spin/docs)"
    printf '%s\n' "• Follow us on Twitter: $(fmt_link @serversideup https://twitter.com/serversideup)"
    printf '%s\n' "• Join our Discord community: $(fmt_link "Discord server" https://serversideup.net/discord)"
    printf '%s\n' "• Get sweet perks, exclusive access, and support: $(fmt_link "Become a sponsor" https://serversideup.net/sponsor)"
    printf '%s\n' $RESET
}

main() {
    # Parse arguments
  while [ $# -gt 0 ]; do
    case $1 in
      --beta) TRACK=beta ;;
      *)
    esac
    shift
  done
  setup_color
  setup_spin
  print_success
}

main $@