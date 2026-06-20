#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${SCRIPT_DIR}/sales_orders.db"

rm -f "${DB_PATH}"

sqlite3 "${DB_PATH}" < "${SCRIPT_DIR}/schema.sql"
sqlite3 "${DB_PATH}" < "${SCRIPT_DIR}/seed.sql"

echo "Created database: ${DB_PATH}"
sqlite3 "${DB_PATH}" ".tables"
