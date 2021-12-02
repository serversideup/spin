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
# Functions for app functionality and tests
############################################################################################################

fmt_error() {
  printf '%sError: %s%s\n' "$BOLD$RED" "$*" "$RESET" >&2
}

check_for_updates() {
    printf "${BOLD}${BLUE}It's been a while since \"spin\" checked for updates. Let's see if there are any updates...${RESET} \n"

    local latest_release
    latest_release=$(get_latest_release)

    if [ "$(get_current_version)" != "$latest_release" ]; then
        perform_upgrade $latest_release
    else
        printf "${BOLD}${GREEN}✅ No updates needed!${RESET} \"spin\" is up-to-date. Now get back to work! \n"
        echo $(date +"%s") > $SPIN_HOME/conf/last_update_check.lock
    fi
}

get_current_version() {
    local local_tag
    local_tag=$(git -C $SPIN_HOME describe --tags --abbrev=0)

    echo $local_tag

}

get_latest_release() {

    source $SPIN_CONFIG_FILE_LOCATION

    if [ "$TRACK" == "beta" ]; then
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

perform_upgrade() {
    # Accepts parameters. Whatever is passed to this function the version that gets installed.

    printf "${BOLD}${YELLOW}🤠 Hey partner, an update is available for \"spin\"! Before running any commands, let's get you updated first...${RESET} \n"
    
    local new_version
    new_version=$1

    echo "${BLUE}Updating spin Spin...${RESET}"

    git clone -c core.eol=lf -c core.autocrlf=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        -c advice.detachedHead=false \
        -c spin.remote=origin \
        --depth=1 --branch "$new_version" "$REMOTE" "$SPIN_HOME" || {
        fmt_error "Update of \"spin\" failed."
        exit 1
    }

    printf "${BOLD}${GREEN}✅ You're now up to date!${RESET} To make sure nothing gets screwed up, try re-running your spin command again. \n"

    exit 0
}

############################################################################################################
# Where the script actually starts
############################################################################################################
check_for_updates