# Changelog

All notable changes to Flow-tracker are recorded here. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `vX.Y.Z`.

## 1.4.0 — liquid glass, second pass

Reworked against the supplied reference. The first attempt put a solid,
oversized capsule on top of the bar; this replaces it with layered glass.

### Changed

- **Three-layer glass material.** The bar is now a blurred backdrop with a
  gentle saturation lift, a low-alpha tint over it, a specular sheen along the
  upper edge and a hairline white rim. The tint is light enough that content
  behind the dock stays visibly distorted through it instead of being painted
  over.
- **The active item is a glass capsule inside the bar**, not a block on top of
  it: a translucent gradient with a bright rim, a soft drop shadow and a hint of
  the accent in its glow. It is inset 5 dp from the bar's edges, so nothing
  spills past the dock.
- **Spring movement.** The capsule now glides on a `SpringSimulation`
  (mass 1, stiffness 520, damping 34) rather than a fixed-duration tween, so
  rapid tab changes carry momentum instead of restarting an ease. Reduced motion
  snaps it to the destination.
- **No labels on the bar.** The reference is icon-only, and the label was
  cramping the capsule. Every destination keeps its semantics label, so screen
  readers still announce "Today", "To-Do", "Plan", "Stats" and "Settings".
- The bar is 58 dp (50 dp folded) with 22 dp icons.

### Removed

- The overhanging lens from the previous build, which read as a floating bubble
  detached from the dock.

### Verified

- Capsule position per destination, inset containment, spring glide versus snap,
  accent propagation across five colours, light/dark/AMOLED, folding, 320 dp
  width, blur presence and the glass-effects fallback.

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
