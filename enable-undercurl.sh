#!/usr/bin/env bash
set -euo pipefail

TERMNAME="${TERM}"
TI_FILE="$(mktemp)"

echo "Using TERM=$TERMNAME"
echo "Dumping terminfo → $TI_FILE"
infocmp -l -x "$TERMNAME" > "$TI_FILE"

echo "Patching terminfo to add Smulx after smul=\\E[4m, ..."
# Write patched output to a second temp file
PATCHED="$(mktemp)"
awk '
  { print }
  /smul=\\E\[4m,/ && !done {
    print "    Smulx=\\E[4:%p1%dm,"
    done=1
  }
' "$TI_FILE" > "$PATCHED"

echo "Compiling patched terminfo..."
tic -x "$PATCHED"

rm -f "$TI_FILE" "$PATCHED"

echo "Done! Verify with:"
echo "  infocmp -l -x \"$TERMNAME\" | grep Smulx"
