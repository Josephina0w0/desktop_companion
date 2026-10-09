# Companion Product Roadmap

This roadmap separates reusable platform work from character-specific content. Promote a feature into the general baseline only after it works in a real variant and has a migration/verification story.

## Foundation — Stable Template

Outcome: a clean general Companion baseline that can be cloned without personal data.

- Single-process coordinator architecture.
- Unified status menu and deterministic cleanup.
- Draggable/resizable desktop pet with fixed metrics pill.
- General tracker with read-only iCloud calendar.
- Unique storage roots and copy-only migration.
- Universal 2, ad-hoc signing, and automated release verification.

Exit gate: two independent variants can be built without editing the baseline or sharing state.

## Configuration — Profile-Driven Variants

Outcome: most new variants are data/configuration work rather than source-wide search and replace.

- Central product profile for names, identifiers, copy, colors, tracker mode, and storage paths.
- State-to-asset manifest.
- Domain pipeline schema with general and specialized field sets.
- Seed-data separation for personal and shareable builds.
- Versioned preference/state schema.

Exit gate: a new character plus tracker domain can be produced with localized code changes and an auditable profile diff.

## Asset Pipeline — Consistent Character Rendering

Outcome: every state looks deliberately sized and anchored.

- Automated alpha-bound inspection.
- Enforced three-surface manifest: top-island Q art, desktop-pet Q art, and control-panel portraits.
- Generic desktop-pet geometry as the versioned default layout contract.
- Visible-height and bottom-anchor normalization report.
- Bottom-aligned aspect-fit rendering with a visible pet-to-pill gap check for wide and tall Q assets.
- Per-state scale/offset overrides only where pose geometry requires them.
- Preview matrix for work, break, idle, water, reminders, AI, and alerts across both desktop-pet and control-panel surfaces.
- Validation for missing alpha, clipped artwork, duplicate state images, and accidental stretching.
- Validation that desktop pets never route to `panelAssetName` and panels never silently route to Q slots.

Exit gate: all state previews pass without manual canvas guessing; wide and tall Q assets sit consistently against the metrics pill, while every panel portrait matches its state mapping and placement mockup.

## Domain Packs — Reusable Trackers

Outcome: tracker specialization becomes composable.

- PhD applications.
- Job applications.
- Study/assessment planning.
- Writing/project milestones.
- Neutral general tracker.

Each pack defines fields, stages, seed-data policy, date semantics, and summary cards without owning app lifecycle or calendar writes.

Exit gate: switching domain packs does not change desktop-pet behavior or storage safety.

## Release Engineering — Repeatable Distribution

Outcome: local and shareable builds have predictable release evidence.

- Version/build policy.
- App and zip verification in one script.
- Bundle-resource manifest and checksum report.
- Permission reset/regrant notes per bundle ID.
- Optional Developer ID signing and notarization path.
- Upgrade smoke test preserving prior state.

Exit gate: a release report can be generated from observable checks rather than assumptions.

## Later — Product Enhancements

Promote only when requested and validated:

- Real launch-at-login support.
- Rich history and export.
- Multiple character profiles in one app.
- More tracker domain packs.
- Opt-in per-app focus metrics.
- Shareable weekly summary cards.
- Accessibility improvements for keyboard-only operation and VoiceOver.
