# iOS app icon (Liquid Glass)

Layer sources for Icon Composer, drawn to Apple's app icon guidelines (HIG, refined for Liquid Glass June 2026): square 1024 × 1024 px unmasked layers, vector, crisp edges, no baked-in shadows, glows, highlights, blur or texture. The system adds specular highlights, refraction, translucency and shadows, and they adapt to size and appearance.

| File | Layer | Notes |
| --- | --- | --- |
| `background.svg` | Background | Linear gradient, top `#123C55` (deep teal-blue) to bottom `#33408E` (indigo). You can recreate it in Icon Composer's background gradient instead of importing. |
| `1-g-ring.svg` | Foreground | The G's 285° ring, white. Echoes the steps ring on Home. |
| `2-g-bar.svg` | Foreground | The crossbar, white, overlapping the ring's end. |
| `3-g-dot.svg` | Foreground | Green leading dot `#3FD07A`, the only accent. |
| `preview.svg` | — | All layers flattened, for previews only. Don't import. |

Geometry: ring centre (500, 512), radius 200, stroke 100, from −75° counter-clockwise to 0°; crossbar 470–750 × 462–562; dot r 30 at −37.5°. The letter is nudged 12 px left of centre so the opening on the right balances optically.

## Building the icon in Icon Composer

Icon Composer ships with Xcode (Xcode › Open Developer Tool › Icon Composer).

1. Create a new icon. Set the background to a linear gradient `#123C55` → `#33408E` (or import `background.svg`).
2. Import `1-g-ring.svg` and `2-g-bar.svg` into one group named Letter, so the glass effect treats the G as a single piece.
3. Import `3-g-dot.svg` into its own group above Letter. Separate groups give the dot its own depth and highlight.
4. Keep Liquid Glass on. Keep the Letter group mostly opaque (translucency low) so the white stays bright; let the dot stay fully opaque.
5. Appearances:
   - Default: as above.
   - Dark: background `#0B1A2A` → `#1A2050`; letter and dot unchanged.
   - Mono (used for clear and tinted): letter white, dot white. The system tints it; the dot still reads as a separate shape.
6. Check at small sizes in the preview and in every appearance (default, dark, clear light/dark, tinted light/dark). Keep features identical across appearances.
7. Export, then add the `.icon` to the Runner target in Xcode in place of the AppIcon in `ios/Runner/Assets.xcassets`.

Android uses the same geometry; its adaptive foreground, background and monochrome layers are still to be made (see `docs/brand/app-icon-prompt.md`).
