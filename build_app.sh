#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="角色效率岛"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
EXECUTABLE_NAME="CharacterEfficiencyIsland"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
RESOURCE_BUNDLE_NAME="CharacterEfficiencyIsland_CharacterEfficiencyIsland.bundle"

export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"

SDK_PATH="${CHARACTER_ISLAND_SDK_PATH:-}"
if [[ -z "$SDK_PATH" ]]; then
  if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
  else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
  fi
fi
export SDKROOT="$SDK_PATH"

cd "$ROOT_DIR"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
ARM64_BUILD_DIR="$ROOT_DIR/.build/arm64"
X86_64_BUILD_DIR="$ROOT_DIR/.build/x86_64"
swift build --disable-sandbox --scratch-path "$ARM64_BUILD_DIR" --sdk "$SDK_PATH" --arch arm64 -c release --product "$EXECUTABLE_NAME"
swift build --disable-sandbox --scratch-path "$X86_64_BUILD_DIR" --sdk "$SDK_PATH" --arch x86_64 -c release --product "$EXECUTABLE_NAME"

# SwiftPM's output layout differs between toolchain generations. Resolve the
# actual bin paths instead of assuming the legacy .build/<triple>/release path.
ARM64_RELEASE_DIR="$(swift build --disable-sandbox --scratch-path "$ARM64_BUILD_DIR" --sdk "$SDK_PATH" --arch arm64 -c release --show-bin-path)"
X86_64_RELEASE_DIR="$(swift build --disable-sandbox --scratch-path "$X86_64_BUILD_DIR" --sdk "$SDK_PATH" --arch x86_64 -c release --show-bin-path)"

/bin/rm -rf "$APP_DIR"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
/bin/mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

/bin/cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
lipo -create \
  "$ARM64_RELEASE_DIR/$EXECUTABLE_NAME" \
  "$X86_64_RELEASE_DIR/$EXECUTABLE_NAME" \
  -output "$MACOS_DIR/$EXECUTABLE_NAME"
/bin/chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

if [[ -d "$ARM64_RELEASE_DIR/$RESOURCE_BUNDLE_NAME" ]]; then
  /bin/cp -R "$ARM64_RELEASE_DIR/$RESOURCE_BUNDLE_NAME" "$RESOURCES_DIR/"
fi

for image in "$ROOT_DIR"/Sources/CharacterEfficiencyIsland/Assets/*.png; do
  /bin/cp "$image" "$RESOURCES_DIR/"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
done

ICON_SOURCE="$ROOT_DIR/Sources/CharacterEfficiencyIsland/Assets/statusIcon.png"
ICONSET="$DIST_DIR/AppIcon.iconset"

swift -sdk "$SDK_PATH" -module-cache-path "$SWIFT_MODULE_CACHE_PATH" \
  "$ROOT_DIR/Packaging/MakeIconset.swift" "$ICON_SOURCE" "$ICONSET" "$RESOURCES_DIR/AppIcon.icns"
xattr -cr "$ICONSET"
/bin/rm -rf "$ICONSET"

xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
/bin/rm -f "$DIST_DIR/$APP_NAME.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIST_DIR/$APP_NAME.zip"

echo "$APP_DIR"
echo "$DIST_DIR/$APP_NAME.zip"
