# Changelog

All notable changes to Flow-tracker are recorded here. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `vX.Y.Z`.

## 1.4.0 — the selection lens

### Changed

- The active destination is now a **lens**: an opaque glass bead with a bright
  rim that sits above the bar and overhangs it by 4 dp, instead of a tinted
  rectangle tucked inside the pill. It casts a soft drop shadow and a whisper of
  the accent colour, so the selection reads as glass resting on glass.
- Only the selected destination is named. Inactive destinations are icon-only,
  which quiets the bar and gives the lens the weight; the name still reaches
  screen readers on every destination through its semantics label.
- The bar is slightly shallower (58 dp, 48 dp folded) so the lens reads wider
  than tall, matching the reference rather than looking like a circle.

### Fixed

- The destination label no longer falls back to the platform font.
  `AnimatedDefaultTextStyle` was given a bare `TextStyle`, which dropped the
  app's family; it now inherits `DefaultTextStyle`, so the label is set in
  Figtree, Google Sans Rounded or the express face as the style requires.
- The lens is positioned by slot offset with the inset in the maths; it no
  longer drifts off its destination.

## 1.3.0 — liquid glass navigation

### Changed

- The bottom navigation bar is now a floating liquid-glass dock: a rounded,
  translucent pill with a backdrop blur, a hairline border and a soft ambient
  shadow. It sits above the system navigation bar and keeps the same five
  destinations — Today, To-Do, Plan, Stats, Settings.
- The active destination is marked by a glass capsule that slides between slots
  over 340 ms with `easeInOutCubic`; the icon tints, scales to 1.08 and its label
  gains weight over 210 ms, so colour and size settle together instead of
  snapping.
- The dock reads its accent from `ColorScheme.primary`, so it follows the accent
  chosen in Appearance & Personalization — presets, hex colours and the AMOLED
  surface — with no hardcoded colour anywhere in the component.
- Glass is drawn once per dock. When the existing "glass effects" setting is off
  the blur node is skipped entirely and the tint carries the surface; when
  animations are disabled in-app or by the platform, the capsule jumps instead of
  sliding and the labels fold instantly.

### Removed

- `lib/app/classic_nav_bar.dart`, replaced by `lib/app/liquid_nav_bar.dart`.

### Fixed

- The navigation buttons expose a tap action to screen readers again: the new
  semantics wrapper is a button with a selected state *and* an action, which
  `accessibility_test.dart` checks.

### Notes

- 11 new tests cover destination taps, capsule position and timing, accent
  propagation across five colours, light/dark/AMOLED, label folding, a 320 dp
  screen, reduced motion, the blur fallback and the single-blur-node budget.

## 1.2.0 — new app icon

### Changed

- New Flow-tracker logo: a woven ribbon that runs from blue through green and
  violet into orange and red, finished with a check mark. It replaces the
  earlier placeholder mark everywhere it appears — launcher icon, adaptive and
  monochrome icon, splash screen, the About screen, share cards, the README
  banner and the social preview.
- The launcher icon now ships as a full-bleed dark tile (#0D0D0D) matching the
  splash background, so the app has no white flash between tapping the icon and
  the first frame.

### Notes

- The artwork was supplied as a single 2048 px PNG with a white surround; the
  white was keyed out, the tile was cropped to its rounded square and the mark
  was lifted onto transparency for the adaptive foreground. No other part of the
  interface changed.

## 1.1.0 — colour customisation

### Added

- **Ten accent presets** — Flow Teal, Ocean Blue, Royal Purple, Emerald Green,
  Sunset Orange, Rose Pink, Crimson Red, Amber Gold, Slate Gray and Indigo, each
  selectable in one tap.
- **Custom colour picker** with a colour wheel and a hex field that accepts
  `#RRGGBB`, `RRGGBB`, `#RGB` and `0xRRGGBB`. Invalid input is rejected with a
  message instead of being guessed at.
- **Live preview** in the picker: a button, a progress bar, a switch and a habit
  card are painted in the candidate colour before it is applied. Apply saves it,
  Cancel leaves the previous colour untouched, and Reset returns to the shipped
  violet.
- The accent is applied app-wide from the single theme source, so navigation,
  buttons, progress, habit completion, charts, heatmaps, the focus timer,
  switches and highlights all follow the choice, in light, dark and AMOLED.
- 21 automated tests for presets, hex validation, persistence, restoration,
  light/dark/AMOLED compatibility, contrast and app-wide propagation.

### Changed

- The Appearance section is now called **Appearance & Personalization**.
- `AppTheme.adaptAccent` now keeps the accent readable instead of only guarding
  the extremes: an accent that falls below the 3:1 contrast WCAG asks of
  non-text elements is walked towards black (light mode) or white (dark mode)
  until it reads. This fixes faint accents such as Amber Gold and Flow Teal on
  light surfaces.

### Fixed

- The accent sheet's action row overflowed on narrow phones; Reset now sits on
  its own line above Cancel and Apply.

## 1.0.0 — first independent release

Flow-tracker starts here as its own product, forked from Streak 2.8.0 by InlitX.
The version number restarts at 1.0.0 because the application identity, package
id and release pipeline are new; the feature set below is the inherited one plus
the additions listed.

### Added

- **True black (AMOLED) mode** — a setting that turns dark-mode surfaces pure
  black for AMOLED panels. Applied to all three interface styles, with the
  accent colour and text contrast preserved.
- `SHA256SUMS.txt` published with every release so downloads can be verified.

### Changed

- Rebranded to Flow-tracker: application name, `com.flowtracker.app` package id,
  launcher icon, adaptive and monochrome icons, splash screen, notification and
  widget labels, About screen and legal notices.
- New release pipeline: one Android workflow that analyses, tests, builds,
  signs, checksums and publishes the APKs, with signing keys held only in
  GitHub Actions secrets.
- Version reset to 1.0.0+1.

### Fixed

- The navigation-rail brand row overflowed by 66 px once the product name grew
  longer than the old one. The label now takes the available width and
  ellipsises instead of overflowing.

### Removed

- Upstream distribution files that do not apply to this project: `fastlane/`
  store metadata, the `fdroid/` build recipe, the iOS/Linux/Windows CI
  workflows, and the old marketing screenshots (they carried the previous
  wordmark).

### Inherited from Streak 2.8.0

Habit creation and management, daily tracking, current/best/perfect streaks,
week, month and year statistics, consistency and activity heatmaps, focus timer
with history and statistics, reminders and notifications, home-screen widgets
(today, stats, heatmap, focus, focus board, to-dos), three interface styles,
colour themes and custom palettes, 28 languages, biometric/PIN app lock, local
backup and restore with integrity checks, to-dos with repeating tasks, and
vacation mode.
