# App icon prompt (Google Gemini)

Concept: a single bold, rounded letter **G** in the app's steps gradient (green to teal) on the deep night-blue used by the Sleep header. The G's open curve echoes the 270° steps ring on Home. Paste the main prompt into Gemini first; use the follow-up prompts in the same chat for the platform variants.

Colours come from `lib/design/palette.dart`. If the palette changes, update the hex values here.

## Main prompt

```
Design a mobile app icon for "Glance Health", a calm, minimal health app that shows steps, sleep and heart rate at a glance. The icon is a single capital letter "G" and nothing else.

OUTPUT
- One square image, 1024 × 1024 px, full bleed: the background colour fills the entire square edge to edge.
- Do NOT draw rounded corners, a squircle mask, a border, a device, a home screen or any mockup. The phone's operating system applies the corner shape; I need the flat square artwork only.
- Flat vector style, as if exported from Figma or Illustrator. Crisp edges, no noise, no texture, no photo realism.

THE LETTER
- One capital "G", centred, occupying about 56% of the icon's width (roughly 570 px wide), optically centred (nudge it very slightly left so it looks balanced, because the G's opening is on the right).
- Geometric, friendly, rounded sans-serif construction in the spirit of the Outfit typeface: a near-perfect circle for the bowl, uniform stroke weight, very bold (stroke about 17% of the letter's height, roughly 100 px), round stroke ends.
- The bowl is drawn as a thick circular arc that starts at about the 1 o'clock position and sweeps counter-clockwise around to the 4 o'clock position, leaving a clean opening on the upper right, like a progress ring that is almost complete.
- The crossbar is short and horizontal, coming in from the right end of the arc towards the centre, ending exactly at the centre point of the circle, with a rounded end. No spur, no serif, no descender.
- Fill the letter with a smooth linear gradient running along the stroke direction from fresh green #2F9E5B (at the top start of the arc) to calm teal #1FA99A (at the crossbar). The gradient must be subtle and clean, two colours only.

BACKGROUND
- A deep, calm night-blue vertical gradient: #121838 at the top to #28316F at the bottom.
- Add one very soft, large, blurred glow behind the letter, centred slightly above the middle, in green #2F9E5B at about 18% opacity, fading smoothly into the background. It should feel like a gentle light, not a neon halo. No other shapes.

FEEL
- Calm, modern, minimal, trustworthy, quietly colourful. Think premium wellness app, not fitness bro, not medical.
- Must read instantly at 40 × 40 px on a busy home screen: strong contrast between the bright G and the dark background, no thin details.

DO NOT INCLUDE
- Any other letters, words, numbers or the app name.
- Hearts, heartbeat / ECG lines, footprints, shoes, moons, stars, leaves, medical crosses, watches, rings around the G, sparkles or emoji.
- 3D extrusion, bevels, glossy highlights, glass or reflections, drop shadows, outlines or strokes around the letter, long shadows.
- Rainbow or multi-colour gradients, purple-pink gradients, neon.
- Rounded-corner frame, white border, padding frame or transparent corners.
```

## Follow-up prompts (same chat)

**Android adaptive icon, foreground layer**

```
Now give me only the foreground layer for an Android adaptive icon: the same "G" with the same green-to-teal gradient, on a fully transparent background, 1024 × 1024 px. Scale the G so it fits inside the central safe circle of 66% of the canvas (about 680 px diameter), with the letter itself about 440 px wide. No background, no glow, nothing else.
```

**Android adaptive icon, background layer**

```
Now give me only the background layer: the same night-blue vertical gradient (#121838 top to #28316F bottom) with the soft green glow, 1024 × 1024 px, full bleed, no letter.
```

**Monochrome (Android 13+ themed icons, iOS tinted icons)**

```
Now give me a monochrome version: the same "G" shape in solid pure white (#FFFFFF), no gradient, no glow, on a fully transparent background, 1024 × 1024 px, the letter about 440 px wide and centred within the central 66% safe area.
```

**iOS dark appearance**

```
Now give me the iOS dark-mode variant: identical "G" with the green-to-teal gradient, centred at the same size as the main icon, on a fully transparent background (iOS supplies the dark backdrop). 1024 × 1024 px, no glow.
```

**Light alternative (optional, for comparison)**

```
Give me one alternative of the main icon with a light background: a soft off-white #F2F4F8 with a very faint green #2F9E5B glow at 12% opacity behind the letter, and the same green-to-teal "G". Everything else identical.
```

## Checking the result

- View it at 40 px and 60 px next to real home-screen icons: the G must stay legible and the opening on the right must still be visible.
- The two gradient hexes should be close to #2F9E5B and #1FA99A; sample them and correct in an editor if Gemini drifts.
- Generate app icon sizes from the 1024 px master with `flutter_launcher_icons` (add it as a dev dependency when the icon is final), using the foreground, background and monochrome layers for Android.
