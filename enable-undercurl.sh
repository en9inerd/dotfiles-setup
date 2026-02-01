#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TERM:-}" ]]; then
    echo "Error: TERM environment variable is not set"
    exit 1
fi

TERMNAME="${TERM}"

# Temp files for terminfo manipulation
SRC=""
DST=""

cleanup() {
    rm -f "$SRC" "$DST"
}
trap cleanup EXIT

SRC="$(mktemp)"
if ! infocmp -l -x "$TERMNAME" > "$SRC" 2>/dev/null; then
    echo "Error: Could not find terminfo entry for $TERMNAME"
    exit 1
fi

if grep -q 'Smulx=' "$SRC"; then
    echo "Smulx already present in $TERMNAME. Nothing to do."
    exit 0
fi

# Insert Smulx after smul=\E[4m,
DST="$(mktemp)"
awk '
  { print }
  /smul=\\E\[4m,/ && !done {
    print "    Smulx=\\E[4:%p1%dm,"
    done=1
  }
' "$SRC" > "$DST"

tic -x "$DST"

echo "Added Smulx and updated terminfo for $TERMNAME."
