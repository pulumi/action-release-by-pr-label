#!/bin/bash
set -euo pipefail

die() {
  echo Usage: "$0" "--repo=<REPO> --pr=<PR> --version=<VERSION>"
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
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${pr-}" ] || [ -z "${version-}" ]; then
  die
fi

label="needs-release/$version"

# Force create is the easiest way to ensure the label exists, add a color just to keep it stable
gh label create "$label" --repo "$repo" --force --color '#BFD4F2'

gh pr edit "$pr" --repo "$repo" --add-label "$label"
