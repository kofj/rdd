#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
exec python3 "$root/scripts/install/manage.py" uninstall --prefix "${RDD_FRAMEWORK_HOME:-$root}" "$@"
