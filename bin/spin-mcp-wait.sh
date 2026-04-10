#!/usr/bin/env bash
#
# MCP stdio bridge for Spin + Laravel Boost.
#
# Solves two problems when running Boost's MCP server inside Docker:
# 1. Cursor/IDEs start MCP servers on launch — Docker may not be ready yet.
#    This script retries until the container is available.
# 2. Docker outputs startup noise (ANSI codes, container messages) that
#    corrupts the JSON-RPC stdio protocol. This script filters stdout to
#    pass only JSON-RPC messages.
#
# Usage (in .env):
#   BOOST_PHP_EXECUTABLE_PATH="./vendor/bin/spin-mcp-wait.sh ./vendor/bin/spin run -T php php"
#
# This script is ONLY for MCP server startup. For all other commands, use
# spin directly: spin run php composer install

set -euo pipefail

is_mcp=0
for arg in "$@"; do
    [ "$arg" = "boost:mcp" ] && is_mcp=1 && break
done

if [ "$is_mcp" -eq 0 ]; then
    echo "Error: spin-mcp-wait.sh is only for starting the MCP server." >&2
    echo "Use 'spin' directly instead. Example: spin run php composer install" >&2
    exit 1
fi

MAX_RETRIES=${SPIN_MCP_MAX_RETRIES:-60}
SLEEP_SECONDS=${SPIN_MCP_RETRY_INTERVAL:-5}
attempt=0

while [ $attempt -lt $MAX_RETRIES ]; do
    "$@" 2>/dev/null | grep --line-buffered '^{'
    exit_code="${PIPESTATUS[0]}"

    [ "$exit_code" -eq 0 ] && exit 0
    [ "$exit_code" -gt 128 ] && exit "$exit_code"

    attempt=$((attempt + 1))
    echo "spin-mcp-wait: attempt $attempt/$MAX_RETRIES failed (exit $exit_code), retrying in ${SLEEP_SECONDS}s..." >&2
    sleep "$SLEEP_SECONDS"
done

echo "spin-mcp-wait: gave up after $MAX_RETRIES attempts." >&2
echo "spin-mcp-wait: Is Docker Desktop running?" >&2
exit 1
