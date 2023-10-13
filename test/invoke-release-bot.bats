#!/usr/bin/env bats

setup() {
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"

  # generate a fake key so we don't error creating the signature
  openssl genrsa -out private.pem 1024
  KEY="$(cat private.pem)"
  rm private.pem
}

@test "release-bot errors are script errors" {
  # trying to post to example.com/release returns a 404
  run invoke_tag_release.sh \
    --repo=pulumi/foo \
    --version=minor \
    --key="$KEY" \
    --endpoint="https://example.com"
  [ "$status" -eq 22 ]
}

@test "fail-fast on invalid versions" {
  # trying to post to example.com/release returns a 404
  run invoke_tag_release.sh \
    --repo=pulumi/foo \
    --version=impact/no-changlog-required \
    --key="$KEY" \
    --endpoint="https://example.com"
  [ "$status" -eq 1 ]
}
