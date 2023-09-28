#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  -v=* | --version=*)
    version="${i#*=}"
    ;;
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ]; then
  die
fi

# check that the right repo is checked out
if [[ $(git remote get-url origin | grep -c "$repo\(\.git\)\?$") -lt 1 ]]; then
  echo "must be run from a full checkout of $repo"
  exit 1
fi

label_prefix="needs-release/"

pr_search_string="label:"
for v in "major" "minor" "patch"; do
  pr_search_string="${pr_search_string}${label_prefix}$v,"
done
if [ -n "${version-}" ]; then
  pr_search_string="${pr_search_string}${label_prefix}$version,"
fi

# find merged PRs with a needs-release/ label for the specified version or an auto version
prs_needing_release=$(
  gh pr list --repo "$repo" --state merged --search "$pr_search_string" \
    --json number --jq '.[].number'
)

for pr in ${prs_needing_release}; do
  # only update PRs whose merge commit is included
  if "$script_dir/is-pr-merge-commit-ancestor-of-commit.sh" --repo="$repo" --pr="$pr" --commit="$commit"; then
    echo "merge_commit of pr #$pr is an ancestor of released commit"
    # find and remove all needs-release/* labels
    to_remove=$(
      gh pr view "$pr" --repo "$repo" --json labels --jq '.[].[].name' || echo "" |
        grep -o "^needs-release/.*$"
    )

    echo "removing labels ($(echo -n "$to_remove" | tr '\n' ',')) from pr #$pr"
    for label in $to_remove; do
      gh pr edit "$pr" --remove-label "$label"
    done
  fi
done
