#!/bin/bash
set -euo pipefail

die() {
  echo Invoke the \`/tag_release\` endpoint on release bot to tag a version of on the specified repo
  echo Usage: "$0" "--repo=<REPO> --version=<VERSION> --key=<KEY> --endpoint=<ENDPOINT> [--channel=<CHANNEL>]"
  exit 1
}

for i in "$@"; do
  case $i in
  -r=* | --repo=*)
    repo="${i#*=}"
    ;;
  -k=* | --key=*)
    key="${i#*=}"
    ;;
  -v=* | --version=*)
    version="${i#*=}"
    ;;
  -e=* | --endpoint=*)
    endpoint="${i#*=}"
    ;;
  -c=* | --channel=*)
    channel="${i#*=}"
    ;;
  --commit=*)
    commit="${i#*=}"
    ;;
  *)
    echo "unknown option $i"
    die
    ;;
  esac
done

if [ -z "${repo-}" ] || [ -z "${key-}" ] || [ -z "${version-}" ] || [ -z "${endpoint:-}" ]; then
  die
fi

if ! echo "$repo" | grep '^pulumi/.*$'; then
  echo release bot can only operate on repos in the pulumi org
  echo include the 'pulumi/' prefix in the repo name
  die
fi
repo=${repo#"pulumi/"}

version_pattern="^\(major\|minor\|patch\|v[0-9]\+\.[0-9]\+\.[0-9]\+\)$"
if [ "$(echo "$version" | grep "$version_pattern")" != "$version" ]; then
  echo "Requested version ($version) does not match expected pattern: '$version_pattern'"
  die
fi

tempdir=$(mktemp -d)
cd "$tempdir"
trap 'rm -rf "$tempdir"; cd -' EXIT

maybe_channel=""
if [ -n "${channel-}" ]; then
  maybe_channel=", 'channel':'$channel'"
fi

commit=${commit:-}

echo -n "{'repo': '$repo', 'version':'$version', 'timestamp':'$(date +%s)', 'commit':'$commit'$maybe_channel}" |
  tr "'" '"' >body

echo "$key" >private_key.pem
openssl dgst -sha256 -sign private_key.pem -hex <body >sig
rm private_key.pem

# some versions of openssl add this prefix which we don't need
sed -e 's/SHA2-256(stdin)= //g' -i".bak" sig

# debug logging body since curl does not log it for us
echo "INFO: calling release bot with body: '$(cat body)'" >&2

max_retries=5
attempt=0
http_body=$(mktemp)
while true; do
  http_code=$(curl -v -s -o "$http_body" -w "%{http_code}" \
    --header "Content-Type: application/json" \
    --header "X-Signature: $(cat sig)" \
    --data-binary @body \
    "$endpoint/tag_release")

  if [ "$http_code" = "429" ] && [ "$attempt" -lt "$max_retries" ]; then
    attempt=$((attempt + 1))
    wait=$((attempt * 30))
    echo "Rate limited by GitHub API. Retrying in ${wait}s (attempt $attempt/$max_retries)..." >&2
    sleep "$wait"
    continue
  fi
  break
done

cat "$http_body"
rm -f "$http_body"

if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
  echo "curl: (22) The requested URL returned error: $http_code" >&2
  exit 22
fi
