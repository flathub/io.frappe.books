#!/bin/bash
# this script checks for new upstream version
# if a new version is available, clones the repo at the new tag,
# regenerates the flatpak-node-generator sources, and updates
# the build sources in the flatpak manifest and appdata file

set -e

api_response=$(curl -s -f https://api.github.com/repos/frappe/books/releases?per_page=1)

upstream_version=$(echo  "$api_response"  | jq -r '.[0].name')

release_date=$(echo "$api_response" | jq -r '.[0].published_at' | cut -dT -f1)

manifest_file='io.frappe.books.yml'
appdata_file='io.frappe.books.appdata.xml'

local_version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$manifest_file" | head -1)

if [[ "$local_version" == "$upstream_version" ]]; then
 echo "No updates found"
 exit 0
fi

echo "Updating from $local_version -> $upstream_version"

# Clone upstream at the new tag to get the yarn.lock
tmp_repo=$(mktemp -d)
trap 'rm -rf "$tmp_repo"' EXIT

echo "Cloning frappe/books at v$upstream_version..."
git clone --depth 1 --branch "v$upstream_version" https://github.com/frappe/books.git "$tmp_repo"

# Get the exact commit SHA for the tag
new_commit=$(git -C "$tmp_repo" rev-parse HEAD)

echo "Commit SHA: $new_commit"

# Regenerate the offline yarn mirror + Electron binary sources
echo "Regenerating generated-sources.json..."
flatpak-node-generator yarn "$tmp_repo/yarn.lock" --electron-node-headers

echo "generated-sources.json regenerated"

# Update the manifest: version tag and commit
old_commit=$(grep -oP '(?<=commit: )\S+' "$manifest_file")

sed -i "s/tag: v[0-9]\+\.[0-9]\+\.[0-9]\+/tag: v$upstream_version/" "$manifest_file"
sed -i "s/commit: $old_commit/commit: $new_commit/" "$manifest_file"

echo "Updated $manifest_file"

# Insert the new release entry at the top of the <releases> section
echo "Updating $appdata_file..."
tmp_appdata=$(mktemp)
awk -v version="$upstream_version" -v date="$release_date" '
/<releases>/ {
    print
    print "    <release version=\"" version "\" date=\"" date "\">"
    print "      <url type=\"details\">https://github.com/frappe/books/releases/tag/v" version "</url>"
    print "    </release>"
    next
}
{ print }
' "$appdata_file" > "$tmp_appdata" && mv "$tmp_appdata" "$appdata_file"

echo "Updated $appdata_file"
echo ""
echo "Done! Manifest updated to v$upstream_version."
echo "Review the changes, then commit:"
echo "  git add io.frappe.books.yml io.frappe.books.appdata.xml generated-sources.json"
echo "  git commit -m 'chore: update to v$upstream_version'"
