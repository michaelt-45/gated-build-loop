#!/bin/sh
# Runs a heavy command (full test suite, evals) under a machine-wide lock so parallel agents do not overload
# a small machine. The lock is released even if the command fails.
# Usage: heavy_lock.sh <command ...>
LOCK=${HEAVY_LOCK:-/tmp/gated-build-loop-heavy.lock}
until mkdir "$LOCK" 2>/dev/null; do sleep 30; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM
"$@"
