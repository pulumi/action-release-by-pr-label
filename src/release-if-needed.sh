#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
  echo Check if there is a PR associated with this commit with a needs-release/* tag
  echo "   and invoke release-bot to release if needed"
  echo Usage: "$0" "--repo=<REPO> --commit=<SHA> --release-bot-key=<KEY> --release-bot-endpoint=<ENDPOINT> [--slack-channel=<CHANNEL>]"
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

if [ -z "${repo-}" ] || [ -z "${commit-}" ] || [ -z "${key-}" ] || [ -z "${endpoint-}" ]; then
  die
fi

version=$("$script_dir/check-if-commit-needs-release.sh" "--repo=$repo" "--commit=$commit" |
  sed "s/needs-release\///")

if [ -z "$version" ]; then
  echo No release tag needed
  exit 0
fi

"$script_dir/invoke_tag_release.sh" \
  --repo="$repo" --version="$version" --key="$key" --endpoint="$endpoint" --channel="${channel:-}"
