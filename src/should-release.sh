#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
  echo "Indicate that this PR should be release as <version>"
  echo Usage: "$0" "--repo=<REPO> --pr=<PR> --version=<VERSION> --release-bot-key=<KEY> --release-bot-endpoint=<ENDPOINT> [--slack-channel=<CHANNEL>]"
  exit 1
}

for i in "$@"; do
  case $i in
  -r=* | --repo=*)
    repo="${i#*=}"
    ;;
  -p=* | --pr=*)
    pr="${i#*=}"
    ;;
  -v=* | --version=*)
    version="${i#*=}"
    ;;
  -k=* | --release-bot-key=*)
    key="${i#*=}"
    ;;
  -e=* | --release-bot-endpoint=*)
    endpoint="${i#*=}"
    ;;
  -s=* | --slack-channel=*)
    channel="${i#*=}"
    ;;
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${pr-}" ] || [ -z "${version-}" ] || [ -z "${endpoint-}" ] || [ -z "${key-}" ]; then
  die
fi

version_pattern="^\(major\|minor\|patch\|v[0-9]\+\.[0-9]\+\.[0-9]\+\)$"
if [ "$(echo "$version" | grep "$version_pattern")" != "$version" ]; then
  echo "Requested version ($version) does not match expected pattern: '$version_pattern'"
  exit 1
fi

# refuse if it already has a release label
labels=$(gh pr view "$pr" --repo "$repo" --json labels --jq '.labels[].name' || echo "")
release_labels=$(echo "$labels" | grep -o "^needs-release/.*$" || echo "")
if [ -n "$release_labels" ]; then
  echo "Cowardly refusing to mark pr #$pr for release because it already has release label"
  echo "Please remove label(s): $(echo "$release_labels" | tr '\n' ',') and try again"
  exit 1
fi

# add the label
"$script_dir/add-needs-release-label-to-pr.sh" --repo="$repo" --pr="$pr" --version="$version"

# if this pr isn't merged, it can't already be built on default branch, so we're done
if [ "$(gh pr view "$pr" --repo "$repo" --json state --jq ".state")" != "MERGED" ]; then
  exit 0
fi

# PR is merged, so we need to check if it's already been built on the default branch

# find the latest successful sha built on the default branch
default_branch=$(gh repo view "$repo" --json defaultBranchRef --jq ".defaultBranchRef.name")
latestVerifiedCommit=$(gh run list \
  --repo "$repo" --workflow "$default_branch" \
  --status success --limit 1 \
  --json headSha --jq ".[].headSha" ||
  echo "")

# if already built on master, invoke release-bot
if "$script_dir/is-pr-merge-commit-ancestor-of-commit.sh" --repo="$repo" --pr="$pr" --commit="$latestVerifiedCommit"; then
  "$script_dir/invoke_tag_release.sh" \
    --repo="$repo" --version="$version" --key="$key" --endpoint="$endpoint" --channel="$channel"
fi
