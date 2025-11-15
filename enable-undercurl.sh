#!/usr/bin/env bash
set -euo pipefail

TERMNAME="${TERM}"

# Dump the current terminfo
SRC="$(mktemp)"
infocmp -l -x "$TERMNAME" > "$SRC"

# If Smulx already exists, exit silently
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

# Compile the updated terminfo
tic -x "$DST"

rm -f "$SRC" "$DST"
echo "Added Smulx and updated terminfo for $TERMNAME."
