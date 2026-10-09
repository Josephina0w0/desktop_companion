# Companion Profile Schema

Use `assets/companion-profile.yaml` as the canonical intake and build record. Remove unused optional fields instead of inventing values.

## Identity

- `product.slug`: lowercase filesystem-safe identifier.
- `product.display_name`: Finder and menu display name.
- `product.executable_name`: Swift product and bundle executable.
- `product.bundle_identifier`: unique reverse-DNS identifier.
- `product.version` and `product.build`: release identity.
- `product.data_root`: unique Application Support folder.

## Character

- `character.name`: visible character name.
- `character.default_position`: normally `bottom-right`.
- `character.default_visible_scale`: visual baseline after alpha-bound normalization.
- `character.metrics_pill`: fixed text, background, and appearance rules.
- `character.layout_baseline`: defaults to `generic-companion` for desktop-pet geometry.
- `character.states`: Q-art mapping for the top island and desktop pet.
- `character.panel_states`: full-proportion portrait mapping for the control panel.

Pet assets and panel assets are separate. `character.states` routes through the Q/small field (`assetName` in the maintained baseline); `character.panel_states` routes through `panelAssetName`. A missing state may deliberately reuse another state only when documented in the profile.

By default, desktop-pet Q art uses the generic frame/footer geometry, proportional fit, and bottom alignment. A user-supplied panel placement mockup applies only to the corresponding portrait state and does not redefine desktop-pet placement.

## Tracker

- `tracker.mode`: `general` or a named domain pack.
- `tracker.fields`: columns persisted for each item.
- `tracker.stages`: ordered user-facing stages.
- `tracker.seed_policy`: `none`, `neutral`, or `personal`.
- `tracker.calendar_access`: default `read-only`.

## State and Migration

- `storage.*`: destination files owned by the new app.
- `migration.*`: optional legacy sources and copy-only rules.

Never derive a destination from a legacy product name. State separation is part of product identity.

## Distribution

- `distribution.audience`: `local`, `friend`, or `public`.
- `distribution.signing`: `ad-hoc` or an explicitly supplied Developer ID path.
- `distribution.architectures`: both `arm64` and `x86_64` for shareable builds.
