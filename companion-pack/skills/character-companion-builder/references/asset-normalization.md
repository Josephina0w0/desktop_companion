# Character Asset Normalization

## Why Canvas Dimensions Are Misleading

Two PNGs can both be 1668×2388 while one character appears half the size because their transparent margins differ. Conversely, two tightly cropped images with different pose proportions should not be forced into identical width and height.

Inspect the alpha bounding box of every state. The relevant geometry is the non-transparent visible region, not the PNG canvas.

## Semantic State Mapping

Maintain an explicit table for:

- working
- break
- idle
- water
- alert
- AI
- reminder first through fourth
- panel equivalents
- status icon

Detect accidental duplicates with checksums. Dedicated AI or reminder artwork must not silently point to the same file unless the profile says so.

Treat filenames and explicit user labels as authoritative. Do not reassign artwork by visual similarity.

Maintain separate mappings for all three surfaces:

| Surface | Allowed artwork | Renderer field |
| --- | --- | --- |
| Top island | State-specific Q art | Small state asset |
| Desktop pet | State-specific Q art | `assetName` |
| Control panel | State-specific full-proportion portrait | `panelAssetName` |

Never use a `panel-*` portrait as a desktop pet and never use a Q asset as a control-panel substitute unless the user explicitly approves that fallback.

## Normalization Rules

1. Preserve the original aspect ratio.
2. Scale using visible alpha height, not canvas height.
3. Center the visible alpha bounds horizontally.
4. Anchor standing/full-body poses to the visible bottom edge.
5. Use per-state overrides for seated, floating, or wide poses rather than distorting them.
6. Keep the metrics pill outside the character scale transform.
7. Do not permanently edit source artwork merely to compensate for runtime layout when alpha-bound normalization can solve it.
8. Use the bundled generic Companion desktop-pet geometry as the default. Proportionally fit and bottom-align Q art (`imageAlignment = .alignBottom` in the AppKit baseline).
9. At 100% scale, target a visible Q-art-to-pill gap of roughly 0–6 points. Measure the visible alpha edge, not only the image-view frame.
10. Keep control-panel portrait placement independent. Follow state-specific mockups and preserve the transparent overflow area so feet, chairs, props, hair, and ribbons are not clipped at the rounded panel body.

Use `scripts/inspect_png_alpha.sh` to report canvas, visible bounds, insets, and coverage. Large differences in top/bottom inset ratios or visible coverage are a review signal.

## Runtime Model

The renderer should derive a normalized visible frame and then apply the saved user character scale. The image remains horizontally centered and bottom-anchored while resizing. State changes reuse the same visible target unless a documented state override applies. Do not rely on `NSImageView`'s default center alignment for wide images; their fitted bitmap will float above the pill.

## Visual QA

Preview every affected state in the packaged app. Check:

- no clipping at maximum scale;
- no tiny character caused by transparent padding;
- consistent foot/bottom position;
- fixed metrics pill size and alignment;
- correct asset for the semantic state;
- Q art on the top island and desktop pet, portrait art only in the control panel;
- visible desktop-pet bottom almost touching the metrics pill for both wide and tall Q assets;
- usable resize edge around transparent artwork;
- acceptable result in both system appearances.
