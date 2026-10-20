# App icon prompt (Google Gemini)

One flattened icon image for iOS (Liquid Glass) and Android, generated in Gemini. The prompt follows Apple's app icon guidelines (Human Interface Guidelines, "App icons", refined for Liquid Glass in June 2026). Paste the main prompt into a new Gemini chat, then use the follow-ups in the same chat.

Colours come from `lib/design/palette.dart`. If the palette changes, update the hex values here.

## What the guidelines mean for this icon

| Guideline | How the prompt applies it |
| --- | --- |
| Square, unmasked artwork; the system rounds the corners | 1024 × 1024 full-bleed square, no rounded corners or frame |
| Keep primary content centred so masking never clips it | G centred, inside the middle 60% of the canvas |
| Embrace simplicity; a minimal number of shapes | Two white shapes (ring and crossbar) and one green dot |
| Prefer a simple background, solid or gradient, that responds well to system lighting | Smooth teal-blue to indigo gradient; mid-dark, not black. The doodle wallpaper is a deliberate exception (see below) |
| Let the system handle highlights, shadows, blur, glows and bevels | None baked in; flat fills only |
| Prefer clearly defined edges; avoid soft or feathered edges | Crisp vector-like edges |
| Avoid thin lines and sharp corners; fine detail looks busy at small sizes | Very bold G with round ends. Doodles are low-contrast and tone-on-tone so they recede at small sizes instead of cluttering |
| A first-letter mnemonic is fine; avoid other text | Only the letter G |
| Keep features identical across default, dark, clear and tinted appearances | Follow-ups change colours only, never shapes |
| Use the default icon as the basis for dark; avoid excessively bright images | Dark follow-up deepens the background, keeps the G |

**Doodle wallpaper (v6):** the background carries an all-over outline doodle pattern, modelled on a reference icon with a dense tone-on-tone wallpaper of themed line icons. Apple prefers simple backgrounds, so the doodles are kept low-contrast and in the background's own hue: up close they give the icon an illustrated, friendly character; at home-screen size and in tinted or clear appearances they fade into the gradient and the white G carries the icon. Earlier versions (v1–v5) are in git history.

## Main prompt

```
Create a mobile app icon for "Glance Health", a calm, minimal health app you check for five seconds each morning to see your steps, last night's sleep and your heart rate. The icon must follow Apple's Liquid Glass app icon guidelines for iOS 26: simple, bold, flat artwork that the system will later light with its own glass highlights, so the image itself carries no effects.

FORMAT
- One square image, exactly 1024 × 1024 px, full bleed: the background fills the entire square edge to edge.
- No rounded corners, no squircle, no circle mask, no border, no frame, no padding, no device, no home screen, no mockup. The operating system applies the corner shape.
- Flat vector-style artwork with crisp, clearly defined edges, as if exported from Figma. No noise, no grain, no texture, no photo realism, no 3D rendering.

BACKGROUND
- A simple, smooth gradient that stays mid-dark so system lighting looks good on it: deep teal-blue #123C55 at the top fading to calm indigo #33408E at the bottom.
- One very large, very soft green bloom (#2F9E5B at about 25% opacity) in the upper-left area, blending smoothly into the gradient, giving a gentle hint of an aurora.

DOODLE WALLPAPER (covers the whole background)
- Fill the entire background, edge to edge and corner to corner, with an even, dense wallpaper of small hand-drawn outline doodles, in the style of a doodle-pattern phone wallpaper or a sketch-icon sticker sheet.
- Style: outline only (no fills), one consistent stroke weight of about 5 px, fully rounded line ends and corners, friendly and slightly playful, like simple line icons drawn by hand. Each doodle is about 55–95 px.
- Colour: tone-on-tone. Every doodle is a lighter tint of the background colour directly behind it (on the teal top a lighter teal, on the indigo bottom a lighter indigo), roughly 15–20% lighter than the background. Clearly visible when you look at the icon up close, but low contrast and calm. Never white, never a contrasting colour.
- Theme: health, sleep and everyday movement. Draw a varied mix of: a running shoe, a pair of footprints, a dotted walking path ending in a map pin, a winding trail over a small mountain, a flight of stairs, a crescent moon, "zzz", a pillow, a bed, an alarm clock, a cloud, a sun, a heart outline, a short pulse line, a water drop, a stopwatch, a slim fitness band, a leaf, a small flower, a cup of tea, a calendar page, a tiny bar chart, an almost-closed progress ring.
- Between the main doodles, scatter small filler marks in the same style and colour: four-point sparkles, little stars, plus signs, small circles and dots, short dashes.
- Layout: about 45–60 doodles plus fillers, evenly spread with consistent spacing like a seamless wallpaper, each rotated at a slight random angle, no two identical doodles side by side, no obvious grid. The pattern runs right up to the letter and continues behind its gaps, but never draws on top of the white letter or the green dot.

THE LETTER "G" (the main element, on top of the doodles)
- A single capital "G", solid pure white #FFFFFF, perfectly flat: no gradient, no glow, no shadow, no outline.
- Built from exactly two overlapping filled shapes with fully rounded ends:
  1. A thick circular ring, like a progress ring: it starts at about the 1 o'clock position and runs counter-clockwise all the way round to the 3 o'clock position (about 285 degrees), leaving an opening on the upper right. The ring's thickness is about 20% of the letter's height (around 100 px), uniform all the way round, with round ends.
  2. A short horizontal capsule (crossbar), the same thickness as the ring, starting at the ring's 3 o'clock end and running left to just past the circle's centre, with a round end.
- Geometric and friendly, like the Outfit typeface: the bowl is a near-perfect circle. No serifs, no spur, no sharp corners anywhere.
- Size and position: the letter is about 49% of the icon's width (around 500 px across), centred vertically, and nudged about 12 px left of centre so the opening on the right balances optically. Everything stays well inside the central 60% of the canvas.

ONE ACCENT
- One small solid green dot, #3FD07A, about 60 px across, sitting in the ring's opening just past the ring's top end (at about 2 o'clock on the ring's path), with a clear gap on both sides. It looks like the bright leading edge of a progress ring. Flat, no glow.

FEEL
- Calm, modern, confident and friendly. Premium wellness, not medical, not a gym.
- Must be instantly recognisable at 40 × 40 px: a bold white G with a green dot on a deep blue-teal gradient; at that size the doodles blend into the background.

DO NOT INCLUDE
- Any glow, halo, drop shadow, inner shadow, highlight, gloss, bevel, emboss, glass, reflection, blur or lens effect. The system adds its own.
- Any texture, grain or noise. Any doodles that are filled, white, brightly coloured, high contrast, larger than about 100 px, or drawn over the letter.
- Any circle, disc, bubble, badge or shape behind the letter.
- Any other letters, words, numbers or the app name (the "zzz" doodle is the only exception).
- Thin lines, sharp corners, or a gradient on the letter.
- Rounded-corner frame, border, transparent corners, watermark or signature.
```

## Follow-up prompts (same chat)

**Dark appearance (iOS dark home screen)**

```
Now make the dark-appearance version of exactly this icon. Keep the letter shapes, sizes, positions and the green dot identical. Deepen the background to a darker gradient, #0B1A2A at the top to #1A2050 at the bottom, with the green bloom reduced to about 15% opacity. Keep the same doodle wallpaper, recoloured as a lighter tint of the new darker background (about 12–15% lighter). Keep the G pure white and the dot #3FD07A. No other changes and still no effects.
```

**Tinted and clear appearances, Android 13+ themed icon (monochrome)**

```
Now make a monochrome version of exactly this icon for tinted and themed icons: the same G and dot, same size and position, in solid pure white #FFFFFF, on a plain solid black #000000 background. No gradient, no bloom, no doodles, no grey tones, no effects.
```

**Android adaptive icon, foreground**

```
Now give me only the foreground for an Android adaptive icon: the same white G and green dot, flat and identical in shape, on a plain solid black #000000 background (I will remove the black). Make the letter about 420 px wide, centred within the central 66% of the 1024 × 1024 canvas. Nothing else.
```

**Android adaptive icon, background**

```
Now give me only the background: the same teal-blue to indigo gradient with the soft green bloom and the same doodle wallpaper, 1024 × 1024 px, full bleed, with no letter and no dot.
```

**If the doodles come out too bright or too faint**

```
Adjust only the doodles: make them a lighter tint of the background behind them, about 15–20% lighter, so they are clearly visible up close but calm and low contrast, like a tone-on-tone wallpaper. Keep everything else identical.
```

**If Gemini adds effects anyway**

```
Remove every glow, shadow, highlight and texture. The letter and dot must be perfectly flat solid colours with crisp edges, and the background a smooth gradient with the tone-on-tone doodle wallpaper. Keep everything else identical.
```

## Shipped icon

`assets/icon/app_icon.png` is the v6 render: the 2048 px Gemini image centre-cropped by 208 px per side (which removes the sparkle watermark) and resized to 1024. It is wired into both platforms with `flutter_launcher_icons` (see README). Dark, tinted and Android themed (monochrome) variants are not made yet.

## Checking the result

- View it at 40 px and 60 px next to real home-screen icons: the G, its opening and the dot must stay clear.
- Sample the colours: the background ends should be close to #123C55 and #33408E, the dot to #3FD07A, and the letter pure white. Correct small drifts in an image editor.
- Gemini adds a visible sparkle watermark in the bottom-right corner. Make sure the final icon is clean before shipping.
- iOS: add the 1024 px image as the app icon (Xcode's single-size app icon, or Icon Composer to add the dark and tinted versions). Android: generate sizes with `flutter_launcher_icons` (add it as a dev dependency when the icon is final), using the adaptive foreground, background and monochrome images.
