#!/bin/zsh
set -euo pipefail

REPO_ROOT="${0:A:h}"
APP_NAME="Sleep Control"
BUILD_APP="$REPO_ROOT/build/$APP_NAME.app"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/$APP_NAME.app"

"$REPO_ROOT/build.zsh"

mkdir -p "$TARGET_DIR"
/usr/bin/ditto "$BUILD_APP" "$TARGET_APP"

printf "Installed %s\n" "$TARGET_APP"

if [[ "${1:-}" == "--launch" ]]; then
  open "$TARGET_APP"
fi
