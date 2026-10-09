# Universal Packaging And Panel Reliability

Use this reference for every shareable character-efficiency-island release.

## Build Invariants

- Build the release executable once for `arm64` and once for `x86_64`.
- Use the same compatible macOS SDK for both builds.
- Keep architecture-specific products in SwiftPM's `.build/arm64-apple-macosx/release` and `.build/x86_64-apple-macosx/release` directories.
- Merge only the executable with `lipo -create`; resource bundles are architecture-independent and can be copied from the arm64 release directory.
- Copy assets and create the application icon after the universal executable is installed in the app bundle.
- For custom `.app` packaging, do not call SwiftPM's generated `Bundle.module` accessor at runtime. Its lookup expects the resource bundle beside `Bundle.main.bundleURL` and can terminate a quarantined/App-Translocated app before fallback code runs. Load images from `Bundle.main.resourceURL`, with an explicit `Contents/Resources/<target>_<target>.bundle` fallback.
- Do not place `Bundle.module` inside an array of fallback URLs. Array elements are evaluated eagerly, so the accessor can crash even when an earlier URL exists.
- Clear extended attributes, ad-hoc sign the completed `.app`, then create the zip.
- Never modify the contents after signing.

The reusable shape of `build_app.sh` is:

```sh
swift build --disable-sandbox --sdk "$SDK_PATH" --arch arm64 -c release --product "$EXECUTABLE_NAME"
swift build --disable-sandbox --sdk "$SDK_PATH" --arch x86_64 -c release --product "$EXECUTABLE_NAME"

lipo -create \
  "$ROOT_DIR/.build/arm64-apple-macosx/release/$EXECUTABLE_NAME" \
  "$ROOT_DIR/.build/x86_64-apple-macosx/release/$EXECUTABLE_NAME" \
  -output "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
```

When the active command-line compiler and default SDK are mismatched, use an installed compatible SDK. Allow an explicit override through `CHARACTER_ISLAND_SDK_PATH`, export it as `SDKROOT`, and keep module caches in the variant's `.build` directory.

## Verification Invariants

Run `scripts/verify_universal_app.sh` once against the `.app` and once against the `.zip`. A release is not complete unless both checks pass.

The verifier must establish all of the following:

- the deliverable contains exactly one discoverable `.app` at its expected level;
- `Info.plist` supplies a bundle executable, short version, and build number;
- the executable contains both `arm64` and `x86_64` slices;
- `codesign --verify --deep --strict` succeeds;
- a zip can be extracted without archive or extended-attribute errors.

## Status Panel Invariants

The following AppKit behavior prevents the “icon is visible but clicking does nothing” failure seen on newer macOS versions:

```swift
item.button?.action = #selector(togglePopover)
item.button?.target = self
item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

panel.hidesOnDeactivate = false

NSApp.activate(ignoringOtherApps: true)
panel.orderFrontRegardless()
panel.makeKey()
```

Keep panel presentation in one shared helper and call it from the status-item toggle and any one-time post-update recovery. For a recovery release, gate the automatic first launch presentation behind a versioned `UserDefaults` boolean so recipients are helped once without seeing the panel forced open forever.
