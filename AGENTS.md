# AI agent instructions

This repository is a clean macOS character-efficiency-island template.

- Read `README.md`, `docs/COPYWRITING.md`, `docs/IMAGE_SLOTS.md`, and `docs/AI_CUSTOMIZATION.md` before customizing.
- Preserve the full feature set unless the user explicitly asks to remove something.
- Never collect or store typed content. Input monitoring may only keep aggregate counts and categories.
- Preserve the natural rolling 60-second APM/EPM model: APM counts non-repeating key presses and mouse clicks; EPM uses the same window but excludes Backspace and Forward Delete; the persistent working island displays EPM.
- Preserve automatic standby after 30 minutes of mouse/keyboard inactivity, break-mode priority, and automatic return to working mode after real input.
- Keep the daily and all-time record lines visible beneath the idle-time row.
- Replace all names, Bundle IDs, storage directories, bridge directories, copy, assets, and packaging names consistently.
- Keep transparent artwork proportional. Tune `CharacterPlacement` instead of stretching or blindly cropping images.
- Preserve reliable status-panel behavior: both mouse-up events, `hidesOnDeactivate = false`, app activation before ordering the panel front, and one shared show helper.
- Run `./build_app.sh`; shareable builds must contain both `arm64` and `x86_64`.
- Run `scripts/verify_universal_app.sh` on both the app and zip before reporting completion.

## Windows branch invariants

- Keep the Windows client in `Windows/CharacterEfficiencyIsland.Windows`; do not replace the macOS target.
- Both Windows flavors are built from the same branch with `-p:Flavor=dynamic-island` or `-p:Flavor=companion`; they share input, state, reminder, record, Codex, tray, and panel code.
- Windows APM/EPM uses background Raw Input, counts non-repeating key-down actions and mouse clicks over a natural rolling 60-second window, and excludes Backspace/Delete from EPM.
- Never persist actual key values, produced characters, clipboard text, window titles, or typed content.
- The dynamic island must always redock after dragging: top is locked to the screen work-area center; left/right remain edge-attached with adjustable vertical position. Side artwork stays upright at the bottom of the island.
- The Windows control panel opens against the inside edge of whichever taskbar contains the clicked tray icon.
- Do not add sleep-prevention code or controls to the Windows client.
- Windows AI completion detection supports Codex only until the user explicitly expands scope.
- Build on Windows with `Windows/build_windows.ps1`, verify with `Windows/verify_windows_package.ps1`, and test the packaged EXE on a real Windows 11 device.
