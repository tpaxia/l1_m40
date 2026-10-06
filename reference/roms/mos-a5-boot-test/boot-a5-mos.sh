#!/bin/sh
# Experimental native A.5 boot with timer and common-status diagnostic overrides.
set -eu
TASK_BOOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export AUTOSCRIPT="$TASK_BOOT_DIR/common-zero-probe.lua"
exec python3 "$TASK_BOOT_DIR/run.py" "${1:-a5-mos-$(date +%Y%m%d-%H%M%S)}" m40-a5 "${2:-200}"
