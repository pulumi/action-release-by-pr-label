#!/bin/bash
set -euo pipefail

die() {
  echo Usage: "$0" "--repo=<REPO> --commit=<SHA>"
  exit 1
}

for i in "$@"; do
  case $i in
  -r=* | --repo=*)
    repo="${i#*=}"
    ;;
  -c=* | --commit=*)
    commit="${i#*=}"
    ;;
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${commit-}" ]; then
  die
fi

# Extract the labels of merged PRs associated with this commit
# and filter for the first label that has the "needs-release/" prefix
gh pr list \
  --repo "$repo" \
  --state merged \
  --search "$commit" \
  --json labels --jq '.[].labels[].name' |
  grep -o "^needs-release/.*$" |
  head -n 1 ||
  echo ""
