#!/bin/bash
# this script checks for new upstream version
# if a new version is available, downloads the
# corresponding artifact & updates the
# build sources in the flatpak manifest

set -e

api_response=$(curl -s -f https://api.github.com/repos/frappe/books/releases?per_page=1)

upstream_version=$(echo  "$api_response"  | jq -r '.[0].name')

release_date=$(echo "$api_response" | jq -r '.[0].published_at' | cut -dT -f1)

manifest_file='io.frappe.books.yml'

tmp_file='/tmp/books.rpm'

local_version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$manifest_file" | head -1)

local_hash=$(yq -r '.modules[0].sources[0].sha256' $manifest_file)

if [[ "$local_version" == "$upstream_version" ]]; then
 echo "No updates found"
 exit 0
fi

echo "Updating from $local_version -> $upstream_version"

wget -O "$tmp_file" "https://github.com/frappe/books/releases/download/v$upstream_version/frappe-books-$upstream_version.x86_64.rpm"

new_hash=$(sha256sum $tmp_file | awk '{print $1}')

sed -i 's/[0-9]\+\.[0-9]\+\.[0-9]\+/'"$upstream_version"'/g' $manifest_file

sed -i "s/$local_hash/$new_hash/g" $manifest_file

rm $tmp_file

echo -e "Manifest updates successfully\nNow updating the appdata file with new changelog"


changelog=$(cat <<EOF
<release version="$upstream_version" date="$release_date">
  <url type="details">https://github.com/frappe/books/releases/tag/v$upstream_version</url>
</release>
EOF
)

echo "$changelog" | wl-copy

echo "Changelog copied to clipboard"
