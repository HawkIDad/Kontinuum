#!/usr/bin/env bash
# redeploy-pi.sh — rebuild the site for the Raspberry Pi preview host and rsync it over.
# WebSite20260919v1-WebSite.md Phase W10.5. Usage: tools/deploy/redeploy-pi.sh
#
# Temporarily points baseUrl at the Pi so canonical/sitemap/OG tags resolve correctly there,
# builds, ships the build, then always restores the repo's real (deferred) baseUrl — even on
# a failed rsync — so `git status` never shows the preview URL as a pending change.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
site="$here/../../site"
site_json="$site/_data/site.json"
preview_url="http://192.168.1.81:8080"
remote="notebytez-pi:/media/data1/notebytez-website/site/"

original_base_url="$(grep -o '"baseUrl": "[^"]*"' "$site_json")"

restore() {
  sed -i '' "s#\"baseUrl\": \"[^\"]*\"#${original_base_url}#" "$site_json"
}
trap restore EXIT

sed -i '' "s#\"baseUrl\": \"[^\"]*\"#\"baseUrl\": \"${preview_url}\"#" "$site_json"
(cd "$site" && npm run build)
rsync -az --delete "$site/_site/" "$remote"

echo "Deployed to $preview_url"
