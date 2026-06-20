#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

exec toolbox --config ./db/tools.yaml --port "${PORT:-5000}" "$@"
