#!/bin/bash
set -euo pipefail

die() {
  echo Usage: "$0" "--repo=<REPO> --pr=<PR> --commit=<SHA>"
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
  -p=* | --pr=*)
    pr="${i#*=}"
    ;;
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${commit-}" ] || [ -z "${pr:-}" ]; then
  die
fi
gh auth status

# check that the right repo is checked out
if [[ $(git remote get-url origin | grep -c "$repo\(\.git\)\?$") -lt 1 ]]; then
  echo "must be run from a checkout of $repo"
  exit 1
fi

# make sure we have the history for the target commit
git fetch origin "$commit"

merge_commit=$(gh pr view "$pr" --repo "$repo" --json mergeCommit --jq ".mergeCommit.oid")
if git merge-base --is-ancestor "$merge_commit" "$commit"; then
  exit 0
else
  exit 2
fi
