#!/bin/bash
set -euo pipefail

die() {
  echo "Get needs-release/* labels for a pr"
  echo Usage: "$0" "--repo=<REPO> --pr=<PR>"
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
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${pr:-}" ]; then
  die
fi

gh pr view "$pr" --repo "$repo" --json labels --jq '.[].[].name' || echo "" | grep -o "^needs-release/.*$" || echo ""
