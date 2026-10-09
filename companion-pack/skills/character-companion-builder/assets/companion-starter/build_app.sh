#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Generic Companion"
EXECUTABLE_NAME="GenericCompanion"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
RESOURCE_BUNDLE_NAME="GenericCompanion_Companion.bundle"

export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

SDK_PATH="${CHARACTER_ISLAND_SDK_PATH:-}"
if [[ -z "$SDK_PATH" ]]; then
  if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
  else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
  fi
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
fi
export SDKROOT="$SDK_PATH"

cd "$ROOT_DIR"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
ARM64_BUILD_DIR="$ROOT_DIR/.build/arm64"
X86_64_BUILD_DIR="$ROOT_DIR/.build/x86_64"
swift build --disable-sandbox --scratch-path "$ARM64_BUILD_DIR" --sdk "$SDK_PATH" --arch arm64 -c release --product "$EXECUTABLE_NAME"
swift build --disable-sandbox --scratch-path "$X86_64_BUILD_DIR" --sdk "$SDK_PATH" --arch x86_64 -c release --product "$EXECUTABLE_NAME"

ARM64_RELEASE_DIR="$(swift build --disable-sandbox --scratch-path "$ARM64_BUILD_DIR" --sdk "$SDK_PATH" --arch arm64 -c release --show-bin-path)"
X86_64_RELEASE_DIR="$(swift build --disable-sandbox --scratch-path "$X86_64_BUILD_DIR" --sdk "$SDK_PATH" --arch x86_64 -c release --show-bin-path)"

# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
/bin/rm -rf "$APP_DIR"
/bin/mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
/bin/cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
lipo -create \
  "$ARM64_RELEASE_DIR/$EXECUTABLE_NAME" \
  "$X86_64_RELEASE_DIR/$EXECUTABLE_NAME" \
  -output "$MACOS_DIR/$EXECUTABLE_NAME"
/bin/chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

if [[ -d "$ARM64_RELEASE_DIR/$RESOURCE_BUNDLE_NAME" ]]; then
  /bin/cp -R "$ARM64_RELEASE_DIR/$RESOURCE_BUNDLE_NAME" "$RESOURCES_DIR/"
fi

for folder in EfficiencyIsland Tracker; do
  /bin/mkdir -p "$RESOURCES_DIR/$folder"
  /bin/cp "$ROOT_DIR"/Sources/Companion/Assets/$folder/* "$RESOURCES_DIR/$folder/"
done

ICON_SOURCE="$ROOT_DIR/Sources/Companion/Assets/EfficiencyIsland/statusIcon.png"
ICONSET="$DIST_DIR/AppIcon.iconset"
swift -sdk "$SDK_PATH" -module-cache-path "$SWIFT_MODULE_CACHE_PATH" \
  "$ROOT_DIR/Packaging/MakeIconset.swift" "$ICON_SOURCE" "$ICONSET" "$RESOURCES_DIR/AppIcon.icns"
xattr -cr "$ICONSET"
/bin/rm -rf "$ICONSET"

xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR" >/dev/null
codesign --verify --deep --strict "$APP_DIR"

/bin/rm -f "$DIST_DIR/$APP_NAME.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIST_DIR/$APP_NAME.zip"

echo "$APP_DIR"
echo "$DIST_DIR/$APP_NAME.zip"
