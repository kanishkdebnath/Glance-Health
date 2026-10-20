# App icon prompt (Google Gemini)

Concept: a single bold, rounded white **G** floating on a night-sky aurora built from the app's own colour blooms (green, teal, indigo), with a frosted-glass disc behind the letter and fine film grain. The G's open arc echoes the 270° steps ring on Home, and a small green dot at its tip echoes the ring's bright end. Paste the main prompt into Gemini first, then use the follow-up prompts in the same chat for the platform variants.

Colours come from `lib/design/palette.dart`. If the palette changes, update the hex values here.

History: v1 (green gradient G on a flat night-blue gradient) looked too flat and plain; v2 makes the G white and adds depth, texture and atmosphere.

## Main prompt

```
Create a mobile app icon for "Glance Health", a calm, beautiful health app you check for five seconds each morning to see your steps, last night's sleep and your heart rate. The icon is one capital letter "G". It should feel like looking up at a quiet night sky just before dawn: calm, a little magical, alive, and premium. Think of a boutique wellness brand, not a medical app and not a gym app.

FORMAT
- One square image, 1024 × 1024 px, full bleed: the artwork fills the square edge to edge.
- Do NOT draw rounded corners, a squircle mask, a frame, a border, a phone, a home screen or a mockup. The operating system applies the corner shape; I need the flat square artwork only.
- Rich digital illustration with real depth and texture, but clean and graphic overall. Not 3D-rendered plastic, not photo-real.

THE LETTER "G"
- One capital "G" in warm white (#FFFFFF at the top easing to a very slightly mint-tinted white #ECFFF5 at the bottom, so it has a gentle sheen and does not look like flat clip art).
- Centred, about 52% of the icon's width (roughly 530 px wide), optically centred: nudge it slightly left because the opening is on the right.
- Geometric, friendly, rounded construction in the spirit of the Outfit typeface: a near-perfect circular bowl, very bold and uniform stroke (about 17% of the letter height, roughly 95 px), fully rounded stroke ends. Confident and soft at the same time.
- The bowl is a thick circular arc starting at about 1 o'clock and sweeping counter-clockwise round to about 4 o'clock, leaving a clean opening on the upper right, like a progress ring that is nearly complete. A short horizontal crossbar comes in from the lower end of the arc and stops exactly at the centre of the circle, with a rounded end. No spur, no serif.
- At the top end of the arc (the 1 o'clock tip) place one small, bright green dot (#3FD07A, about 40 px across) sitting just beyond the rounded tip, with a tiny soft green glow, like the bright leading edge of a progress ring. This is the only accent on the letter.
- The G emits a soft, wide, green-white glow (#9EF0C0 at about 20% opacity, blur radius about 60 px) so it feels lit from within, and casts a very soft, low-contrast shadow downwards (#0A0E1A at about 35%, offset 12 px down, blur 30 px) so it floats slightly above the background.

BEHIND THE LETTER: A FROSTED GLASS DISC
- A large circle centred behind the G, about 76% of the icon width (roughly 780 px), made of frosted glass: very slightly lighter than the background (white at about 6–8% opacity), softly blurring the aurora behind it, with a thin luminous rim along its upper-left edge (white at about 25% opacity fading to nothing around the circle) as if catching light from the top left. Subtle, not a hard outline.

BACKGROUND: NIGHT AURORA
- Base: a deep night-blue vertical gradient from #0E1330 at the top to #28316F at the bottom.
- Over it, soft overlapping colour blooms like a gentle aurora or mesh gradient:
  - a large green bloom (#2F9E5B, about 45% opacity) rising from the upper left,
  - a teal bloom (#1FA99A, about 35% opacity) drifting across the upper right,
  - an indigo-violet bloom (#5B5FD9 to #8A6FF0, about 40% opacity) pooling in the lower right.
  The blooms are large, smooth and slightly asymmetric, blending into each other with no hard edges, and the overall image stays dark enough that the white G pops.
- A soft vignette darkens the four corners slightly.
- A fine, even film-grain texture across the whole background and glass disc (about 3–4% monochrome noise) so it feels tactile and printed rather than flat digital. The grain must be subtle: invisible at small sizes, felt at large sizes. Keep the letter itself clean, with no grain on it.

FEEL AND QUALITY
- Calm, modern, quietly colourful, with character: the letter should feel like a small moon or a glowing dial in a night sky.
- Must read instantly at 40 × 40 px on a busy home screen: the white G is the brightest thing in the image by far; background detail stays soft and low contrast.
- Balanced composition with generous breathing room around the letter.

DO NOT INCLUDE
- Any other letters, words, numbers or the app name.
- Stars, sparkles, twinkles, moons, planets, hearts, heartbeat / ECG lines, footprints, shoes, leaves, medical crosses, watches, rings around the G other than the frosted disc, or emoji.
- Hard 3D extrusion, bevels, chrome, glossy plastic highlights, lens flares, light rays, long shadows, outlines or strokes around the letter.
- Neon, rainbow or saturated pink and purple gradients.
- Rounded-corner frame, white border, padding frame, transparent corners, watermarks or signatures.
```

## Follow-up prompts (same chat)

**Android adaptive icon, foreground layer**

```
Now give me only the foreground layer for an Android adaptive icon: the same white "G" with its green tip dot, inner sheen, soft glow and soft drop shadow, on a fully transparent background, 1024 × 1024 px. Scale it so the letter is about 420 px wide, centred inside the central safe circle of 66% of the canvas (about 680 px diameter). No background, no glass disc.
```

**Android adaptive icon, background layer**

```
Now give me only the background layer: the same night aurora (night-blue base, green, teal and indigo blooms, vignette, fine grain) with the frosted glass disc centred, 1024 × 1024 px, full bleed, no letter.
```

**Monochrome (Android 13+ themed icons, iOS tinted icons)**

```
Now give me a monochrome version: the same "G" shape with its tip dot, in solid pure white (#FFFFFF), flat, with no sheen, glow, shadow or texture, on a fully transparent background, 1024 × 1024 px, the letter about 420 px wide and centred within the central 66% safe area.
```

**iOS dark appearance**

```
Now give me the iOS dark-mode variant: the same white "G" with its green tip dot and soft glow, centred at the same size as the main icon, on a fully transparent background (iOS supplies the dark backdrop). 1024 × 1024 px, no aurora, no glass disc.
```

**Warmer alternative (optional, for comparison)**

```
Give me one alternative of the main icon where the aurora leans towards dawn: keep the night-blue base and the white G, but make the lower bloom a soft apricot (#F28C5B at about 30%) instead of indigo-violet, as if the sun is about to rise. Everything else identical.
```

## Checking the result

- View it at 40 px and 60 px next to real home-screen icons: the G and its opening must stay legible, and the tip dot may disappear at small sizes (that's fine).
- Gemini adds a visible sparkle watermark in the bottom-right corner. The shipped icon must be clean, so treat Gemini output as the concept, then rebuild the final artwork as vector (SVG) with the exact palette hexes and export the 1024 px master from that.
- Generate app icon sizes from the master with `flutter_launcher_icons` (add it as a dev dependency when the icon is final), using the foreground, background and monochrome layers for Android.
