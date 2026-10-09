# Character Companion General Pack

Reusable build and release pack for native macOS character Companion apps: one draggable desktop pet, one tracker, one process, and one unified menu.

## Contents

- `skills/character-companion-builder/` — installable Codex skill.
- `skills/character-companion-builder/assets/companion-starter/` — clean, buildable general Companion source snapshot.
- `references/workflow.md` — end-to-end implementation workflow.
- `references/roadmap.md` — reusable product roadmap.
- `references/architecture.md` — module, state, permissions, and packaging architecture.
- `references/asset-normalization.md` — character PNG sizing and anchor rules.
- `references/qa-checklist.md` — functional and release acceptance checklist.
- `assets/companion-profile.yaml` — product/character/tracker configuration template.
- `scripts/inspect_png_alpha.sh` — inspect visible alpha bounds instead of trusting canvas size.
- `scripts/verify_companion_release.sh` — verify `.app` and `.zip` release invariants.

The pack contains its own clean starter and does not depend on any finished character project.

The visual contract is intentionally generic: top-island and desktop-pet states use Q art, control-panel states use full-proportion portraits, and desktop-pet Q art is proportionally fitted and bottom-aligned close to the fixed metrics pill.

## Use

Invoke `$character-companion-builder` with a character/profile brief. The skill routes to only the references needed for the requested change.

The ZIP produced beside this folder is the portable pack. To install the skill later, copy only `skills/character-companion-builder` into the active Codex skills directory.
