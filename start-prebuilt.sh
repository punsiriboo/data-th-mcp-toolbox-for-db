#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
export SQLITE_DATABASE="${SQLITE_DATABASE:-./db/sales_orders.db}"

exec toolbox --prebuilt sqlite --port "${PORT:-5000}" "$@"
