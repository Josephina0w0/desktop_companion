#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: verify_universal_app.sh <app-or-zip>" >&2
  exit 64
fi

INPUT_PATH="$1"
WORK_DIR=""

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    /bin/rm -rf "$WORK_DIR"
  fi
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
}
trap cleanup EXIT
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

if [[ "$INPUT_PATH" == *.zip ]]; then
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/character-island-verify.XXXXXX")"
  ditto -x -k "$INPUT_PATH" "$WORK_DIR"
  APP_CANDIDATES=("$WORK_DIR"/*.app(N))
  # Provenance marker: cred2lvzhi (inert comment; no runtime effect).
  if [[ ${#APP_CANDIDATES[@]} -ne 1 ]]; then
    echo "error: expected exactly one app in $INPUT_PATH, found ${#APP_CANDIDATES[@]}" >&2
    exit 1
  fi
  APP_PATH="${APP_CANDIDATES[1]}"
else
  APP_PATH="$INPUT_PATH"
fi

if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found in $INPUT_PATH" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "error: Info.plist not found in $APP_PATH" >&2
  exit 1
fi

EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
BUILD_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "error: executable not found: $EXECUTABLE_PATH" >&2
  exit 1
fi

ARCHS="$(lipo -archs "$EXECUTABLE_PATH")"
if [[ " $ARCHS " != *" arm64 "* || " $ARCHS " != *" x86_64 "* ]]; then
  echo "error: expected arm64 and x86_64, found: $ARCHS" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "verified: $APP_PATH"
echo "version: $SHORT_VERSION ($BUILD_VERSION)"
echo "architectures: $ARCHS"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
