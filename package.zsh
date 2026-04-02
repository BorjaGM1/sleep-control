#!/bin/zsh
set -euo pipefail

REPO_ROOT="${0:A:h}"
APP_NAME="Sleep Control"
BUILD_APP="$REPO_ROOT/build/$APP_NAME.app"
DIST_DIR="$REPO_ROOT/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-macos-unsigned.zip"

"$REPO_ROOT/build.zsh"

mkdir -p "$DIST_DIR"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$BUILD_APP" "$ZIP_PATH"

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

printf "Packaged %s\n" "$ZIP_PATH"
printf "Checksum %s.sha256\n" "$ZIP_PATH"
