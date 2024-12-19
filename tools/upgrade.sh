#!/bin/bash
# This upgrade script was heavily inspired by talented devs of OhMyZSH https://github.com/ohmyzsh/ohmyzsh

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

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() {
    return 0
  }
else
  is_tty() {
    return 1
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
    [ "$FORCE_HYPERLINK" -ne 0 ]
    return
  fi

  # If stdout is not a tty, it doesn't support hyperlinks
  if ! is_tty; then
    return 1
  fi

  # DomTerm terminal emulator (domterm.org)
  if [ -n "$DOMTERM" ]; then
    return 0
  fi

  # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
  if [ -n "$VTE_VERSION" ]; then
    [ "$VTE_VERSION" -ge 5000 ]
    return
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

  # In all other cases do not support hyperlinks
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
  if is_tty; then
    printf '\033[4m%s\033[24m\n' "$*"
  else
    printf '%s\n' "$*"
  fi
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  if is_tty; then
    printf '`\033[2m%s\033[22m`\n' "$*"
  else
    printf '`%s`\n' "$*"
  fi
}

fmt_error() {
  printf '%sError: %s%s\n' "$BOLD$RED" "$*" "$RESET" 1>&2
}

############################################################################################################
# Functions for app functionality and tests
############################################################################################################

check_for_updates() {
    if ! command_exists git; then
        fmt_error '"git" is not installed.'
        exit 1
    fi

    printf "${BOLD}${BLUE}It's been a while since \"spin\" checked for updates. Let's see if there are any updates...${RESET} \n"

    local latest_release
    latest_release=$(get_latest_release)

    if [ "$(get_current_version)" != "$latest_release" ]; then
        perform_upgrade $latest_release
    else
        printf "${BOLD}${GREEN}✅ No updates needed!${RESET} \"spin\" is up-to-date. Now get back to work! \n"
        date "+%s" > "${SPIN_HOME}/cache/.spin-last-update"
    fi
}

get_current_version() {
    git -C "$SPIN_HOME" describe --tags --abbrev=0
}

get_latest_release() {
    source "$SPIN_CONFIG_FILE_LOCATION"

    if [ "$TRACK" == beta ]; then
        # Get the latest release (including pre-releases). We just want the 
        # absolute latest release, regardless of pre-release or stable
        curl --silent --header "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/serversideup/spin/releases" \
            | grep '"tag_name":' \
            | sed -E 's/.*"([^"]+)".*/\1/' \
            | head -n 1
        return
    fi

    # Get latest stable release
    curl --silent --header "Accept: application/vnd.github.v3.sha" \
        "https://api.github.com/repos/serversideup/spin/releases/latest" \
        | grep '"tag_name":' \
        | sed -E 's/.*"([^"]+)".*/\1/'
}

perform_upgrade() {
    # Accepts parameters. Whatever is passed to this function the version that gets installed.

    printf "${BOLD}${YELLOW}🤠 Hey partner, an update is available for \"spin\"! Before running any commands, let's get you updated first...${RESET} \n"
    
    local new_version
    new_version=$1

    echo "${BLUE}Updating Spin to \"$new_version\"...${RESET}"

    git -C "$SPIN_HOME" fetch --all --tags > /dev/null

    # Set git-config values known to fix git errors
    # Line endings
    git -C "$SPIN_HOME" config core.eol lf
    git -C "$SPIN_HOME" config core.autocrlf false
    # zeroPaddedFilemode fsck errors
    git -C "$SPIN_HOME" config fsck.zeroPaddedFilemode ignore
    git -C "$SPIN_HOME" config fetch.fsck.zeroPaddedFilemode ignore
    git -C "$SPIN_HOME" config receive.fsck.zeroPaddedFilemode ignore
    git -C "$SPIN_HOME" config rebase.autoStash true

    if ! git -C "$SPIN_HOME" checkout "tags/$new_version" -b "$new_version"; then
        fmt_error 'Update of "spin" failed.'
        exit 1
    fi

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
    printf '%s\n' "• See what's new by reading the release notes: $(fmt_link "View the latest release notes" https://github.com/serversideup/spin/releases)"
    printf '%s\n' "• Get latest news and updates by follow on Twitter: $(fmt_link @serversideup https://twitter.com/serversideup)"
    printf '%s\n' "• Meet friends and get help on our community: $(fmt_link "Join our Discord Community" https://serversideup.net/discord)"
    printf '%s\n' "• Get sweet perks, exclusive access, and professional support: $(fmt_link "Become a sponsor" https://serversideup.net/sponsor)"
    printf '%s\n' $RESET
    printf '\n'
    printf "${BOLD}${GREEN}✅ Spin has been upgraded to $new_version!${RESET} ${BOLD}${YELLOW}To make sure nothing messed up during the update, try re-running your spin command again.${RESET} \n"

    exit 0
}

############################################################################################################
# Where the script actually starts
############################################################################################################
check_for_updates