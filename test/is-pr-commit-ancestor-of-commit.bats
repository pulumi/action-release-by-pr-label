#!/usr/bin/env bats

setup() {
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"
}

@test "PR is ancestor" {
  is-pr-merge-commit-ancestor-of-commit.sh --repo=pulumi/action-release-by-pr-label --pr=1 --commit=929d87a7f7de13b44b6cf806458274089603bd52
}

@test "PR is not ancestor" {
  run is-pr-merge-commit-ancestor-of-commit.sh --repo=pulumi/action-release-by-pr-label --pr=1 --commit=e8da7f284922fb8a2c649411bcc8ddb491ca56e3
  [ "$status" -eq 2 ]
}
