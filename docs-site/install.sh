#!/usr/bin/env bash
#
# RDD Framework Installer (Short URL)
#
# Usage:
#   curl -fsSL https://cdn.jsdelivr.net/gh/kofj/rdd/install.sh | sh
#
# For full options, see: https://github.com/kofj/rdd#installation
#

set -e

# Short URL redirect to full installer
exec curl -fsSL https://raw.githubusercontent.com/kofj/rdd/main/scripts/install/install.sh | sh -s -- "$@"
