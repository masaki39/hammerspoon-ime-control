#!/usr/bin/env bash
set -euo pipefail

BUMP="${1:-patch}"
INIT_LUA="Hanten.spoon/init.lua"
ZIP_PATH="Spoons/Hanten.spoon.zip"
DOCS_JSON="docs/docs.json"

# Refuse to release from a dirty working tree so the zip matches the commit
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: working tree is not clean. Commit or stash changes first." >&2
    exit 1
fi

# Read current version
CURRENT=$(grep -oE 'obj\.version = "[^"]+"' "$INIT_LUA" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Bump version
case "$BUMP" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Usage: $0 {major|minor|patch}"
        exit 1
        ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"

if git rev-parse -q --verify "refs/tags/v${NEW}" > /dev/null; then
    echo "Error: tag v${NEW} already exists." >&2
    exit 1
fi

# Update version in init.lua
sed -i "" "s/obj\.version = \"[^\"]*\"/obj.version = \"$NEW\"/" "$INIT_LUA"

# Update version in docs/docs.json
sed -i "" "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW\"/" "$DOCS_JSON"

# Regenerate zip (exclude Finder metadata)
mkdir -p Spoons
rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" Hanten.spoon/ -x "*.DS_Store" > /dev/null

# Commit & tag
git add "$INIT_LUA" "$ZIP_PATH" "$DOCS_JSON"
git commit -m "Release v${NEW}"
git tag "v${NEW}"

echo "Released v${NEW}"
echo "Next: git push && git push --tags"
