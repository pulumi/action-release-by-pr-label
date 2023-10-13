#!/usr/bin/env bats

setup() {
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"
}

@test "only returns the needs-release label" {
  # this commit is the merge commit for PR #1 which has both a release label and a spurious label
  output=$(src/check-if-commit-needs-release.sh --repo=pulumi/action-release-by-pr-label --commit=8de77745e9d0022317fdc3efe30e4a785f93a329)
  [ "$output" = "needs-release/v0.0.1" ]
}

@test "empty output when we can't find the PR" {
  output=$(src/check-if-commit-needs-release.sh --repo=pulumi/action-release-by-pr-label --commit=foobar)
  [ "$output" = "" ]
}
