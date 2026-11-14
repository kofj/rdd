#!/usr/bin/env bash
# HTTPS bootstrap + shared Python lifecycle manager. macOS/Linux, Bash 3.2+.
set -euo pipefail
source_dir=''
version='latest'
action='install'
forward=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_dir="${2:?--source requires a directory}"
      shift 2
      ;;
    --version)
      version="${2:?--version requires a value}"
      shift 2
      ;;
    --upgrade)
      action='install'
      shift
      ;;
    --uninstall)
      action='uninstall'
      shift
      ;;
    --no-path) shift ;; # PATH is never modified; retained for compatibility.
    --agent | --prefix | --user-home)
      forward+=("$1" "${2:?option requires a value}")
      shift 2
      ;;
    --replace-skills | --dry-run)
      forward+=("$1")
      shift
      ;;
    --help | -h)
      echo 'Usage: bash install.sh [--agent claude|codex|both] [--source DIR] [--version TAG]'
      echo '  [--prefix DIR] [--no-path] [--upgrade|--uninstall] [--replace-skills] [--dry-run]'
      echo 'Requires Python 3.8+. Default target: both (upgrade preserves prior targets).'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done
command -v python3 >/dev/null || {
  echo 'Install Python 3.8+ first.' >&2
  exit 1
}
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)'
# Validate host selection before any download or filesystem mutation.
for ((i = 0; i < ${#forward[@]}; i++)); do
  if [[ "${forward[$i]}" == '--agent' ]]; then
    case "${forward[$((i + 1))]}" in claude | codex | both) ;; *)
      echo 'Invalid --agent' >&2
      exit 2
      ;;
    esac
  fi
done
bootstrap_tmp=''
trap '[[ -z "$bootstrap_tmp" ]] || rm -rf "$bootstrap_tmp"' EXIT
if [[ -z "$source_dir" && "$action" == uninstall ]]; then
  source_dir="${RDD_FRAMEWORK_HOME:-$HOME/.rdd-framework}"
  for ((i = 0; i < ${#forward[@]}; i++)); do
    if [[ "${forward[$i]}" == '--prefix' ]]; then source_dir="${forward[$((i + 1))]}"; fi
  done
fi
if [[ -z "$source_dir" ]]; then
  command -v curl >/dev/null || {
    echo 'curl is required for downloading RDD.' >&2
    exit 1
  }
  if [[ "$version" == latest ]]; then
    version=$(curl -fsSL https://api.github.com/repos/kofj/rdd/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
  fi
  case "$version" in
    main | master) url='https://github.com/kofj/rdd/archive/refs/heads/main.tar.gz' ;;
    *)
      [[ "$version" =~ ^[A-Za-z0-9._-]+$ ]] || {
        echo 'Invalid version' >&2
        exit 2
      }
      url="https://github.com/kofj/rdd/archive/refs/tags/$version.tar.gz"
      ;;
  esac
  bootstrap_tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$bootstrap_tmp/source.tar.gz"
  mkdir "$bootstrap_tmp/source"
  # Reject archive paths/links that could escape the temporary directory.
  python3 - "$bootstrap_tmp/source.tar.gz" "$bootstrap_tmp/source" <<'PY'
import sys, tarfile
from pathlib import PurePosixPath
with tarfile.open(sys.argv[1]) as archive:
    for entry in archive.getmembers():
        path = PurePosixPath(entry.name)
        if path.is_absolute() or '..' in path.parts or not (entry.isfile() or entry.isdir() or entry.issym() or entry.islnk()):
            raise SystemExit('Unsafe archive member: ' + entry.name)
    # Repository discovery symlinks are not needed in installed copies.
    archive.extractall(sys.argv[2], members=[m for m in archive.getmembers() if m.isfile() or m.isdir()])
PY
  candidates=("$bootstrap_tmp/source/"*)
  [[ ${#candidates[@]} -eq 1 && -d "${candidates[0]}" ]] || {
    echo 'Invalid source archive' >&2
    exit 1
  }
  source_dir="${candidates[0]}"
fi
[[ -f "$source_dir/scripts/install/manage.py" ]] || {
  echo 'This source/release predates Codex support. Select a release containing Phase 5 or use --source with this checkout.' >&2
  exit 1
}
if [[ "$action" == install ]]; then
  if [[ "$version" != latest ]]; then forward+=(--version "$version"); fi
  python3 "$source_dir/scripts/install/manage.py" install --source "$source_dir" "${forward[@]}"
else
  python3 "$source_dir/scripts/install/manage.py" uninstall "${forward[@]}"
fi
