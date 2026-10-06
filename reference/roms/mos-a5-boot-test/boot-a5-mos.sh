#!/bin/sh
# Native A.5 boot using the compiled UC042 and GO363 fixes.
set -eu
TASK_BOOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export AUTOSCRIPT="$TASK_BOOT_DIR/observe-keys.lua"
exec python3 "$TASK_BOOT_DIR/run.py" "${1:-a5-mos-$(date +%Y%m%d-%H%M%S)}" m40-a5 "${2:-200}"
