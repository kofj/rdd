#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "${VERSION}" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "Error: Invalid version format. Expected: v1.0.0 or v1.0.0-beta.1"
    exit 1
fi

VERSION_NUM="${VERSION#v}"
if ! grep -q "## \[${VERSION_NUM}\]" CHANGELOG.md; then
    echo "Warning: Version ${VERSION_NUM} not found in CHANGELOG.md"
    echo "Please update CHANGELOG.md first."
    exit 1
fi

echo "Creating release ${VERSION}..."
git tag -a "${VERSION}" -m "Release ${VERSION}"
echo "Pushing tag to origin..."
git push origin "${VERSION}"
echo "Done! GitHub Actions will create the release automatically."
