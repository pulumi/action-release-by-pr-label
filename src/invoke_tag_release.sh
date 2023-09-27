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

tempdir=$(mktemp -d)
cd "$tempdir"
trap 'rm -rf "$tempdir"; cd -' EXIT

maybe_channel=""
if [ -n "${channel-}" ]; then
  maybe_channel=", 'channel':'$channel'"
fi

echo -n "{'repo': '$repo', 'version':'$version', 'timestamp':'$(date +%s)'$maybe_channel}" |
  tr "'" '"' >body

echo "$key" >private_key.pem
openssl dgst -sha256 -sign private_key.pem -hex <body >sig
rm private_key.pem

# some versions of openssl add this prefix which we don't need
sed -e 's/SHA2-256(stdin)= //g' -i".bak" sig

curl -v -X POST \
  --header "Content-Type: application/json" \
  --header "X-Signature: $(cat sig)" \
  --data-binary @body \
  "$endpoint/tag_release"
