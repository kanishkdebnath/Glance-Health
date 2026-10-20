# App icon prompt (Google Gemini)

> **iOS (Liquid Glass) uses its own clean version.** Apple's guidelines ask for layered vector artwork with a simple solid or gradient background and no baked-in glows, shadows, blur or texture, because the system adds those effects itself and fine detail turns busy in the clear and tinted appearances. The ready-made layers are in [`assets/icon/ios/`](../../assets/icon/ios/README.md): same G, ring, crossbar and green dot, on a teal-to-indigo gradient. The textured, doodled artwork below is for Android, the Play Store, and marketing. See the Liquid Glass prompt at the end for a Gemini concept preview.

Concept: a single bold, rounded white **G** with a small green tip dot, floating directly on a night-sky aurora built from the app's own colour blooms (green, teal, indigo). The whole background carries a faint tone-on-tone doodle pattern and a soft paper-grain texture, so it feels illustrated up close and clean from a distance. The G's open arc echoes the 270° steps ring on Home. Paste the main prompt into Gemini first, then use the follow-up prompts in the same chat for the platform variants.

Colours come from `lib/design/palette.dart`. If the palette changes, update the hex values here.

History:
- v1: green gradient G on a flat night-blue gradient. Too flat and plain.
- v2: white G, aurora background, frosted glass disc, film grain.
- v3: added faint hand-drawn doodles. Gemini drew them far too bright, and the glass disc read as a white bubble.
- v4: no disc; the doodles become an all-over tone-on-tone pattern at very low contrast, plus paper texture.

## Main prompt

```
Create a mobile app icon for "Glance Health", a calm, beautiful health app you check for five seconds each morning to see your steps, last night's sleep and your heart rate. The icon is one capital letter "G" on a textured night-sky background. It should feel like a quiet night sky just before dawn, sketched in a designer's notebook: calm, a little magical, crafted, and premium. Think of a boutique wellness brand, not a medical app and not a gym app.

FORMAT
- One square image, 1024 × 1024 px, full bleed: the artwork fills the square edge to edge.
- Do NOT draw rounded corners, a squircle mask, a frame, a border, a phone, a home screen or a mockup. The operating system applies the corner shape; I need the flat square artwork only.
- Rich digital illustration with depth and texture, but clean and graphic overall. Not 3D-rendered plastic, not photo-real.

THE LETTER "G"
- One capital "G" in warm white (#FFFFFF at the top easing to a very slightly mint-tinted white #ECFFF5 at the bottom, a gentle sheen so it does not look like flat clip art).
- It sits directly on the background. There is NO circle, bubble, disc, glass shape, badge, plate or halo shape behind it.
- Centred, about 54% of the icon's width (roughly 550 px wide), optically centred: nudge it slightly left because the opening is on the right.
- Geometric, friendly, rounded construction in the spirit of the Outfit typeface: a near-perfect circular bowl, very bold and uniform stroke (about 17% of the letter height, roughly 95 px), fully rounded stroke ends.
- The bowl is a thick circular arc starting at about 1 o'clock and sweeping counter-clockwise round to about 4 o'clock, leaving a clean opening on the upper right, like a progress ring that is nearly complete. A short horizontal crossbar comes in from the lower end of the arc and stops exactly at the centre of the circle, with a rounded end. No spur, no serif.
- Just beyond the top tip of the arc (1 o'clock) place one small, bright green dot (#3FD07A, about 40 px across) with a tiny soft green glow, like the bright leading edge of a progress ring. This is the only accent on the letter.
- Lighting: a soft, diffuse green-white glow around the letter (#9EF0C0 at about 15% opacity, blur radius about 70 px) that simply fades into the background with no visible edge, and a very soft low-contrast shadow below (#0A0E1A at about 30%, offset 10 px down, blur 30 px) so it floats slightly.

BACKGROUND: NIGHT AURORA
- Base: a deep night-blue vertical gradient from #0E1330 at the top to #28316F at the bottom.
- Over it, soft overlapping colour blooms like a gentle aurora or mesh gradient:
  - a large green bloom (#2F9E5B, about 40% opacity) rising from the upper left,
  - a teal bloom (#1FA99A, about 30% opacity) drifting across the upper right,
  - an indigo-violet bloom (#5B5FD9 to #8A6FF0, about 35% opacity) pooling in the lower right.
  Large, smooth, slightly asymmetric, no hard edges. The overall image stays dark so the white G is by far the brightest element.
- A soft vignette darkens the four corners slightly.

ALL-OVER DOODLE PATTERN (very faint)
- Cover the entire background, edge to edge and behind the letter too, with a loose hand-drawn doodle pattern, like a sketchbook page seen through dusk.
- Drawn TONE-ON-TONE: each doodle is only slightly lighter than the colour directly beneath it (about 4–6% lighter in brightness), never white, never mint, never a contrasting colour. On the green bloom the doodles are a slightly lighter green, on the indigo they are a slightly lighter indigo, and so on. They must be barely noticeable, like a watermark or a pattern embossed into paper; you only see them when you look closely.
- Single-weight wobbly monoline strokes (about 3 px), imperfect and human, like a fine gel pen.
- Doodle vocabulary, small (30–80 px each): dotted footpaths that curl into loops, gentle wavy lines like slow breathing, small crescent outlines, tiny "z z" handwriting, small heart outlines, little spirals, four-point sparkle crosses, squiggles, loose dots, small open circles like almost-closed rings.
- Dense enough to read as a pattern (roughly 40–60 doodles), evenly distributed but irregular: varied rotation and spacing, no grid, no obvious repeating tile, no two identical doodles side by side.
- Around the letter itself the pattern thins out slightly so the G's edges stay crisp, but there is no empty circle or shape around the G.
- At 60 px icon size the pattern must be completely invisible; the icon should then read as just a white G on a glowing night gradient.

SURFACE TEXTURE
- Over the whole background (not on the letter), add a subtle tactile texture: fine film grain (about 3% monochrome noise) plus a faint paper or risograph fibre texture, so it feels printed and crafted rather than flat digital.
- The texture sits on top of the doodles and softens them further. Keep it even and quiet: no scratches, no dust specks, no heavy grunge.

FEEL AND QUALITY
- Calm, modern, quietly colourful, with character: the letter feels like a glowing dial in a night sky drawn in a notebook.
- Must read instantly at 40 × 40 px on a busy home screen: a crisp white G on a dark glowing gradient, background detail invisible at that size.
- Balanced composition with breathing room around the letter.

DO NOT INCLUDE
- Any circle, bubble, disc, glass shape, badge, plate, ring or halo shape behind or around the G.
- White, mint or high-contrast doodles; doodles must be tone-on-tone and barely visible.
- Any other letters, words, numbers or the app name (the tiny "z z" doodles are the only exception).
- Any solid, filled, bright or large symbols: stars, moons, planets, hearts, heartbeat / ECG lines, footprints, shoes, leaves, medical crosses, watches or emoji.
- Hard 3D extrusion, bevels, chrome, glossy plastic highlights, lens flares, light rays, long shadows, outlines or strokes around the letter.
- Neon, rainbow or saturated pink and purple gradients.
- Rounded-corner frame, white border, padding frame, transparent corners, watermarks or signatures.
```

## Follow-up prompts (same chat)

**If the doodles are still too visible**

```
Make the doodle pattern half as visible again. Each doodle should be only a few percent lighter than the colour beneath it, so the pattern is barely noticeable even at full size. Keep everything else exactly the same.
```

**Android adaptive icon, foreground layer**

```
Now give me only the foreground layer for an Android adaptive icon: the same white "G" with its green tip dot, sheen, soft glow and soft drop shadow, on a fully transparent background, 1024 × 1024 px. Scale it so the letter is about 420 px wide, centred inside the central safe circle of 66% of the canvas (about 680 px diameter). Nothing else.
```

**Android adaptive icon, background layer**

```
Now give me only the background layer: the same night aurora (night-blue base, green, teal and indigo blooms, vignette), the same faint tone-on-tone doodle pattern across the whole square, and the same grain and paper texture, 1024 × 1024 px, full bleed, no letter and no shapes in the centre.
```

**Monochrome (Android 13+ themed icons, iOS tinted icons)**

```
Now give me a monochrome version: the same "G" shape with its tip dot, in solid pure white (#FFFFFF), flat, with no sheen, glow, shadow or texture, on a fully transparent background, 1024 × 1024 px, the letter about 420 px wide and centred within the central 66% safe area.
```

**iOS dark appearance**

```
Now give me the iOS dark-mode variant: the same white "G" with its green tip dot and soft glow, centred at the same size as the main icon, on a fully transparent background (iOS supplies the dark backdrop). 1024 × 1024 px, no background, no pattern.
```

**Warmer alternative (optional, for comparison)**

```
Give me one alternative of the main icon where the aurora leans towards dawn: keep the night-blue base, the white G and the faint doodle pattern, but make the lower bloom a soft apricot (#F28C5B at about 30%) instead of indigo-violet, as if the sun is about to rise. Everything else identical.
```

## Checking the result

- View it at 40 px and 60 px next to real home-screen icons: the G and its opening must stay legible, and the doodle pattern should vanish completely.
- Gemini adds a visible sparkle watermark in the bottom-right corner. The shipped icon must be clean, so treat Gemini output as the concept, then rebuild the final artwork with the exact palette hexes and export the 1024 px master from that. The doodle and paper layers can be redrawn or sourced as a licensed texture.
- Generate app icon sizes from the master with `flutter_launcher_icons` (add it as a dev dependency when the icon is final), using the foreground, background and monochrome layers for Android.

## Liquid Glass concept prompt (iOS, optional)

The real iOS icon is built from the SVG layers in `assets/icon/ios/` in Icon Composer. Use this only to preview the mood in Gemini.

```
Create a flat, layered app icon artwork for "Glance Health" designed for Apple's Liquid Glass icon style (iOS 26). It is the source artwork before the system adds glass effects, so it must be clean, simple and flat.

FORMAT
- Square 1024 × 1024 px, full bleed, no rounded corners, no mask, no mockup.

BACKGROUND
- A simple smooth linear gradient, top deep teal-blue #123C55 to bottom indigo #33408E. Nothing else in the background: no texture, no pattern, no grain, no blooms.

FOREGROUND
- One bold geometric capital "G" in solid white #FFFFFF with crisp, sharp-edged vector shapes (not feathered), built from two overlapping filled shapes: a thick circular ring (stroke about 20% of the letter height, round ends) that runs counter-clockwise from about 1 o'clock round to 3 o'clock, leaving an opening on the upper right, and a short capsule-shaped crossbar that runs from the 3 o'clock end of the ring to just left of the circle's centre.
- One small solid green dot #3FD07A (about 60 px across) sitting in the ring's opening, just past the ring's top end, like the bright leading edge of a progress ring.
- The letter is about 49% of the icon width, centred, nudged slightly left.

DO NOT INCLUDE
- Any glow, drop shadow, highlight, bevel, gloss, glass, reflection, blur or gradient on the letter; any texture, doodles or noise; any other text or symbols; rounded corners or borders.
```
