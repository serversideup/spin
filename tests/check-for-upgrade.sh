#!/usr/bin/env bash
# Regression tests for check_for_upgrade() in a non-interactive shell.
#
# Run from anywhere:
#   ./tests/check-for-upgrade.sh
set -u

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT=$(dirname "$SCRIPT_DIR")
TEST_INSTALL_DIR=$(mktemp -d)/.spin
TIMEOUT_IN_SECONDS=15
failures=0

cleanup() {
  rm -rf "$(dirname "$TEST_INSTALL_DIR")"
}
trap cleanup EXIT

run_with_timeout() {
  # macOS has no "timeout", so watch the process ourselves.
  local seconds="$1"; shift
  local cmd_pid watchdog_pid status

  # "<&0" is explicit on purpose: bash points a background command at /dev/null
  # unless its stdin is redirected, which would hide the hang we're testing for.
  "$@" > /dev/null 2>&1 <&0 &
  cmd_pid=$!
  ( sleep "$seconds"; kill -9 "$cmd_pid" 2> /dev/null ) &
  watchdog_pid=$!

  wait "$cmd_pid"
  status=$?
  kill "$watchdog_pid" 2> /dev/null
  wait "$watchdog_pid" 2> /dev/null

  return $status
}

assert_exit_code() {
  local description="$1"
  local expected="$2"
  local actual="$3"

  if [ "$actual" == "$expected" ]; then
    echo "✅ $description"
  else
    echo "❌ $description (expected exit $expected, got $actual)"
    failures=$((failures + 1))
  fi
}

build_test_installation() {
  # "installation_type" reports "user" for a ".spin" directory, which is the only
  # installation type that checks for upgrades.
  mkdir -p "$TEST_INSTALL_DIR"
  cp -R "$REPO_ROOT/bin" "$REPO_ROOT/lib" "$REPO_ROOT/conf" "$REPO_ROOT/tools" "$TEST_INSTALL_DIR/"
  cp "$REPO_ROOT/conf/spin.example.conf" "$TEST_INSTALL_DIR/conf/spin.conf"
  mkdir -p "$TEST_INSTALL_DIR/cache"
}

clear_update_cache() {
  rm -f "$TEST_INSTALL_DIR/cache/.spin-last-update"
}

build_test_installation

# An open, empty pipe on stdin is what CI runners and coding agents hand to spin.
# It never reaches EOF, so an unguarded "read" blocks until something kills it.
open_empty_pipe_on_stdin() {
  local fifo="$(dirname "$TEST_INSTALL_DIR")/stdin-fifo"
  mkfifo "$fifo"
  exec 3<> "$fifo"
}

open_empty_pipe_on_stdin

clear_update_cache
run_with_timeout "$TIMEOUT_IN_SECONDS" "$TEST_INSTALL_DIR/bin/spin" version <&3
assert_exit_code "Open pipe on stdin with no update cache doesn't hang" 0 $?

clear_update_cache
run_with_timeout "$TIMEOUT_IN_SECONDS" "$TEST_INSTALL_DIR/bin/spin" version < /dev/null
assert_exit_code "Closed stdin with no update cache doesn't hang" 0 $?

if [ -f "$TEST_INSTALL_DIR/cache/.spin-last-update" ]; then
  echo "✅ Skipped update check is recorded so it doesn't re-prompt"
else
  echo "❌ Skipped update check is recorded so it doesn't re-prompt"
  failures=$((failures + 1))
fi

run_with_timeout "$TIMEOUT_IN_SECONDS" "$TEST_INSTALL_DIR/bin/spin" version < /dev/null
assert_exit_code "Closed stdin with a fresh update cache succeeds" 0 $?

clear_update_cache
SPIN_SKIP_UPDATE_CHECK=true run_with_timeout "$TIMEOUT_IN_SECONDS" "$TEST_INSTALL_DIR/bin/spin" version < /dev/null
assert_exit_code "SPIN_SKIP_UPDATE_CHECK=true succeeds" 0 $?

if [ "$failures" -gt 0 ]; then
  echo "$failures test(s) failed."
  exit 1
fi

echo "All tests passed."
