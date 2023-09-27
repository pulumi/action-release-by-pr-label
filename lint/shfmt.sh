#!/bin/bash

set -euo pipefail

DIR="$1"
if command -v shfmt >/dev/null 2>&1; then
  echo "runing shfmt on '$DIR/**/*.sh'"
  shfmt -f "$DIR" | xargs shfmt -w -s -i 2
else
  echo "shfmt is not installed. Skipping shell script formatting."
  echo "Follow instructions here to install: https://github.com/patrickvane/shfmt"
  echo "or use 'devbox shell' (https://www.jetpack.io/devbox/docs/quickstart/)"
  if [ -n "$CI" ]; then
    exit 1
  fi
fi
