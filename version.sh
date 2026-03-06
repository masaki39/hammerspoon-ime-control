#!/usr/bin/env bash
set -euo pipefail

BUMP="${1:-patch}"
INIT_LUA="ImeControl.spoon/init.lua"
ZIP_PATH="Spoons/ImeControl.spoon.zip"
SPOON_LIST="Spoons/spoon_list.json"

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

# Update version in init.lua
sed -i "" "s/obj\.version = \"[^\"]*\"/obj.version = \"$NEW\"/" "$INIT_LUA"

# Update release in spoon_list.json
sed -i "" "s/\"release\": \"v[^\"]*\"/\"release\": \"v$NEW\"/" "$SPOON_LIST"

# Regenerate zip
mkdir -p Spoons
rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" ImeControl.spoon/ > /dev/null

# Commit & tag
git add "$INIT_LUA" "$ZIP_PATH" "$SPOON_LIST"
git commit -m "Release v${NEW}"
git tag "v${NEW}"

echo "Released v${NEW}"
