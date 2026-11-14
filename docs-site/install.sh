#!/bin/sh
# POSIX-compatible bootstrap; run the downloaded installer with Bash.
set -eu
rdd_bootstrap=$(mktemp)
trap 'rm -f "$rdd_bootstrap"' EXIT HUP INT TERM
curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh -o "$rdd_bootstrap"
bash "$rdd_bootstrap" "$@"
