# This upgrade script was heavily inspired by talented devs of OhMyZSH https://github.com/ohmyzsh/ohmyzsh

################################################
# ⏰ Automatic: Check for Last Update
################################################
check_last_update(){
  LAST_UPDATE_DATE="$(cat $SCRIPTPATH/last_update_check_date.txt | tr -d " \t\n\r")"
  # Run date checks based on the OS (because the "date" command differs between the two)
  case "$RUNNING_OS" in
      Linux*)     DATE_THRESHOLD=$(date -d 'now - 7 days' +%s);;
      Darwin*)    DATE_THRESHOLD=$(date -v -7d +%s)
  esac

  if (( LAST_UPDATE_DATE <= DATE_THRESHOLD )); then
    # Check for an internet connection before comparing versions.
    if internet_is_connected; then
      compare_version
    else
      echo "I cannot connect to `https://infra.521hosting.net` so I am skipping the update check...."
    fi
  fi
}