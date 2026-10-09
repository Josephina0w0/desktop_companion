# Companion Workflow

## 1. Classify the Request

Choose one mode before editing:

- New character variant.
- New tracker-domain variant.
- Existing Companion feature change.
- Character asset correction.
- State migration or compatibility repair.
- Release/package-only task.

Record the source baseline and exact target directory. A request to create a new variant never authorizes edits to finished source projects.

## 2. Capture the Product Profile

Instantiate `assets/companion-profile.yaml`. Resolve only choices that materially affect product behavior:

- Names and bundle identity.
- Personal versus shareable data.
- Tracker domain and required pipeline fields.
- Character state assets and copy.
- Separate Q-art mappings for top island/desktop pet and portrait mappings for the control panel.
- Permission-dependent features.
- Migration sources.
- Signing/distribution target.

## 3. Establish a Clean Target

Copy the chosen baseline while excluding `.git`, `.build`, and `dist`. Assign new identifiers before the first build. Preserve the baseline's checksums for later comparison when non-modification is a requirement.

## 4. Configure Architecture and Storage

Confirm one app entry point and one status item. Keep feature coordinators separate. Change every storage path and migration rule to the new product root. Add new persisted fields with backward-compatible decoding.

## 5. Map and Normalize Assets

Create an explicit state-to-file table before changing layout. Treat the supplied filename/state labels as authoritative. Inspect alpha bounds with `scripts/inspect_png_alpha.sh`; do not infer visible size from pixel dimensions alone.

Keep the surfaces distinct:

- Top island: state-specific Q art.
- Desktop pet: the same state-specific Q slot, routed through `assetName`.
- Control panel: state-specific full-proportion portrait, routed through `panelAssetName`.

Normalize visible height, horizontal center, and the correct semantic anchor. For the desktop pet, use the generic starter's frame and footer geometry, use proportional fit with bottom alignment, and judge the visible alpha edge. Wide Q images must not float above the metrics pill because of vertically centered letterboxing. Control-panel portraits retain independent per-state placement and transparent overflow.

## 6. Configure the Tracker

Start with general fields, then add only domain fields named by the profile. Seed data must be appropriate for the target audience:

- Personal builds may contain user-specific records when explicitly supplied.
- Shareable builds must contain neutral examples or no records.
- Imported calendars remain immutable bundle resources.
- Live EventKit access remains read-only unless explicitly broadened.

## 7. Implement Interactions

Verify interaction priority so gestures do not collide:

1. Character-edge drag resizes the character.
2. Character-body drag moves the pet.
3. A click without meaningful movement toggles the control panel.
4. A click outside the control panel hides it.

Keep reminder, idle, break, and AI state changes independent of window position and saved character scale.

## 8. Migrate Safely

On first launch only:

- Copy a known legacy file when the destination is absent.
- Never overwrite a destination.
- Never delete or move a source.
- Log a migration failure and continue with defaults.

Test migration with copies or a controlled state directory. Restore test-generated counters, checkbox changes, window positions, and titles before delivery.

## 9. Build and Verify

Build the packaged app, not only a development executable. Run the release verifier on both `.app` and `.zip`, then launch the packaged app and complete the relevant sections of `qa-checklist.md`.

For character changes, preview every affected state in isolation. At minimum, inspect both a wide/near-square Q image and a tall Q image at 100% desktop-pet scale, confirm the visible lower edge is about 0–6 points above the metrics pill, and verify the full silhouette remains visible. Then open the control panel and confirm every state uses its portrait slot and follows any user-supplied placement mockup without unintended clipping. For tracker changes, exercise editing, save/reload, calendar denial, and window layering. Confirm one process and one status icon.

## 10. Hand Off

Report:

1. Target source directory.
2. Architecture and tracker mode.
3. State and migration behavior.
4. Permissions and first-launch behavior.
5. Tests actually performed.
6. Known limitations.
7. Clickable absolute paths to the `.app` and `.zip`.
8. Existing sources and data confirmed untouched.
