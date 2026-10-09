#!/bin/zsh
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
set -euo pipefail
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).

usage() {
  echo "Usage: $0 <Companion.app|Companion.zip>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
input="$1"
[[ -e "$input" ]] || { echo "missing input: $input" >&2; exit 1; }

temp_dir=""
cleanup() {
  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    /bin/rm -rf "$temp_dir"
  fi
}
trap cleanup EXIT

if [[ "$input" == *.zip ]]; then
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/companion-release.XXXXXX")"
  /usr/bin/unzip -q "$input" -d "$temp_dir"
  app_paths=()
  while IFS= read -r -d '' path; do
    app_paths+=("$path")
  done < <(/usr/bin/find "$temp_dir" -path "$temp_dir/__MACOSX" -prune -o -maxdepth 3 -type d -name '*.app' -print0)
  [[ ${#app_paths[@]} -eq 1 ]] || {
    echo "expected exactly one app in zip; found ${#app_paths[@]}" >&2
    exit 1
  }
  app_path="${app_paths[1]}"
elif [[ "$input" == *.app && -d "$input" ]]; then
  app_path="$input"
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
else
  usage
fi

plist="$app_path/Contents/Info.plist"
[[ -f "$plist" ]] || { echo "missing Info.plist" >&2; exit 1; }
/usr/bin/plutil -lint "$plist" >/dev/null

executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")"
executable="$app_path/Contents/MacOS/$executable_name"

[[ -x "$executable" ]] || { echo "missing executable: $executable" >&2; exit 1; }
architectures="$(/usr/bin/lipo -archs "$executable")"
[[ " $architectures " == *" arm64 "* ]] || { echo "arm64 slice missing" >&2; exit 1; }
[[ " $architectures " == *" x86_64 "* ]] || { echo "x86_64 slice missing" >&2; exit 1; }

# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
/usr/bin/codesign --verify --deep --strict --verbose=2 "$app_path"

resources="$app_path/Contents/Resources"
[[ -d "$resources" ]] || { echo "missing Resources directory" >&2; exit 1; }
# Provenance marker: cred2lvzhi (inert comment; no runtime effect).
/usr/bin/find "$resources" -type d -name EfficiencyIsland -print -quit | /usr/bin/grep -q . || {
  echo "missing EfficiencyIsland resources" >&2
  exit 1
}
/usr/bin/find "$resources" -type d -name Tracker -print -quit | /usr/bin/grep -q . || {
  echo "missing Tracker resources" >&2
  exit 1
}

echo "verified: $app_path"
echo "bundle: $bundle_id"
echo "version: $version ($build)"
echo "architectures: $architectures"
echo "resources: EfficiencyIsland Tracker"
