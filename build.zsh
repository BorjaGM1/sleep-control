#!/bin/zsh
set -euo pipefail

REPO_ROOT="${0:A:h}"
APP_NAME="Sleep Control"
APP_ROOT="$REPO_ROOT/build/$APP_NAME.app"
BIN_PATH="$APP_ROOT/Contents/MacOS/$APP_NAME"
PLIST_PATH="$APP_ROOT/Contents/Info.plist"
SDK_PATH="$(xcrun --show-sdk-path)"

mkdir -p "$APP_ROOT/Contents/MacOS" "$APP_ROOT/Contents/Resources"

swiftc \
  -sdk "$SDK_PATH" \
  -framework AppKit \
  "$REPO_ROOT/main.swift" \
  -o "$BIN_PATH"

cp "$REPO_ROOT/Info.plist" "$PLIST_PATH"

# Ad-hoc signing avoids immediate "app is damaged" style failures on many Macs.
codesign --force --deep --sign - "$APP_ROOT" >/dev/null 2>&1 || true

printf "Built %s\n" "$APP_ROOT"
