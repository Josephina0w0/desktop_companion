---
name: character-efficiency-island
description: Customize and package the generic macOS efficiency island and Companion template without mixing Q desktop-pet art and full-proportion control-panel art.
---

# Generic Character Efficiency Island

Use this skill when a fork user wants to turn this repository into a named character, mascot, or brand build. The repository is intentionally generic and contains no finished character variant.

## Required reading

1. Read `README.md`, `docs/FORK_AND_CUSTOMIZE.md`, `docs/COPYWRITING.md`, and `docs/IMAGE_SLOTS.md`.
2. Read `templates/character-profile.json` and collect every value before editing code.
3. For the desktop-pet build, read `companion-pack/skills/character-companion-builder/SKILL.md` and its starter README.

## Non-negotiable invariants

- Treat the user's filenames and state labels as authoritative; never substitute an image because it looks similar.
- Keep Q art on the top island and desktop pet. Keep full-proportion portraits on control panels.
- Preserve the complete visible subject. Do not crop feet, props, clothing, or the bottom of a desktop pet.
- Fit images proportionally and bottom-align desktop-pet art close to the fixed metrics strip. Do not vertically center wide Q images.
- Give every build a unique display name, Bundle ID, executable name, storage directory, and Windows mutex ID.
- Keep input privacy: count events and categories, never store typed content.
- Build macOS as Universal 2, sign after resource changes, and verify both `.app` and `.zip`.
- Build and verify both Windows flavors when the fork includes Windows output.

## Workflow

1. Create a new branch and copy the profile template.
2. Prepare all required transparent PNGs and inspect their visible alpha bounds.
3. Update macOS names, copy, identifiers, and `characterPlacement` values.
4. Copy the Companion starter, update its product identifiers and resource paths, and keep its asset surfaces separate.
5. Create `Windows/CharacterPacks/<slug>/profile.json` and its 19-image `Assets/` directory if a custom Windows pack is needed.
6. Build, launch the packaged app, and inspect every state instead of relying on compilation alone.
7. Run the platform verification scripts and document permissions and known limitations.

## Completion evidence

Report the exact output paths, the verification commands that passed, and which assets were checked. State that the original upstream repository and all unrelated local data were left untouched.
