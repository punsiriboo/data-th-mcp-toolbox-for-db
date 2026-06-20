#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SQLITE_DATABASE="${SQLITE_DATABASE:-${SCRIPT_DIR}/litellm.db}"

if [[ ! -f "${SQLITE_DATABASE}" ]]; then
  echo "Database not found: ${SQLITE_DATABASE}"
  echo "Run ./init_db.sh first."
  exit 1
fi

# macOS AirPlay Receiver uses port 5000 — avoid it by default
PORT="${PORT:-8080}"

echo "Starting MCP Toolbox (prebuilt sqlite) on http://127.0.0.1:${PORT}"
echo "Database: ${SQLITE_DATABASE}"
echo "Tools: list_tables, execute_sql"
echo "Press Ctrl+C to stop."
echo ""
echo "Open UI:  ./start-prebuilt.sh --ui"
echo "          then visit http://127.0.0.1:${PORT}/ui"
echo ""
echo "Manual:   SQLITE_DATABASE=./litellm.db toolbox --prebuilt sqlite --port ${PORT} --ui"

exec toolbox --prebuilt sqlite --port "${PORT}" "$@"
