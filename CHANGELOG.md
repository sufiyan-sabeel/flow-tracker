# Changelog

All notable changes to Flow-tracker are recorded here. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `vX.Y.Z`.

## 1.8.0 — multi-platform releases

### Added

- **Five-platform release pipeline.** Tagging `vX.Y.Z` now builds Android (APK per
  ABI plus an AAB), iOS (unsigned IPA), Windows (EXE and MSI installers), Linux
  (AppImage and DEB) and macOS (DMG and PKG), verifies each artifact, and attaches
  the verified set to a single GitHub release with `SHA256SUMS.txt`.
- **A separate CI workflow** runs formatting, analysis and the full test suite on
  every push and pull request, so the release pipeline is not the first place a
  broken build is discovered.
- **macOS support**, which the project did not have: the platform project is now
  generated and configured with the Flow-tracker identity.
- Windows installers: an Inno Setup script for the EXE and a WiX definition for
  the MSI, both packaging the complete Flutter runtime rather than a lone binary.

### Fixed

- The iOS bundle identifier was still the upstream `com.streak.app`, and the App
  Group shared with the widget extension still carried it. Both are now
  `com.flowtracker.app`, matching Android.
- The Windows executable's file properties credited the previous author; the
  publisher is now Umaiz Sufiyan with the upstream notice retained in the
  copyright string.
- The Linux launcher entry still said "Streak" in its name, comment and Exec
  line. It now says Flow-tracker and launches `flow-tracker`.

### Notes

- iOS and macOS artifacts are unsigned: no signing credentials are configured in
  CI, and the release notes say so rather than implying they are installable.
- Release notes list signing status per platform and mark what is not notarized.

## 1.7.0 — brand identity and report corrections

### Fixed

- **The reported statistics are correct now.** "All history" no longer starts at
  the year 2000: it starts at your earliest real record, so a report no longer
  divides one completion by nine thousand scheduled days and prints 0%. A habit
  is also only counted from the day it was created, so a habit added last week
  is not marked down for the weeks before it existed.
- Completions logged on a day a habit was not scheduled are reported as
  *entries*, separately from scheduled wins, instead of distorting the rate.
- The statistics labels no longer read "Best current streak"; the cards are
  Current streak, Best streak, Scheduled days done, Completions logged, Days
  tracked and Consistency.
- The date range shown on the export screen no longer prints a placeholder year
  for "all history".

### Changed

- **PDF covers are redesigned**: the official Flow-tracker mark, wordmark and a
  report category chip at the top; a 30 pt title with a descriptive subtitle;
  reporting period, generation time and design in a metadata row; headline
  numbers; an "Inside this report" contents strip; a short note explaining how
  the figures are calculated; and a footer with the creator credit and version.
- **The real logo replaces the orange square** in every PDF, in the header of
  every content page as well as the cover. The transparent mark is now bundled
  with the app so the document can embed it offline.
- **Typography and spacing follow a documented scale**: 30 pt cover title,
  18.5 pt section titles, 13 pt subsections, 10 pt body, 8.5 pt tables, 8 pt
  metadata, 7.5 pt footers, with 44 pt margins and consistent card and cell
  padding.
- **Tables alternate row shading and repeat their header** every 20 rows, so a
  long table is readable across pages instead of continuing headless.
- Charts gained a habit-completion bar set alongside daily activity and category
  breakdowns.

## 1.6.0 — offline PDF reports

### Added

- **PDF export, generated entirely on the device.** Settings → PDF Export &
  Reports opens a dashboard where you choose the report, the date range, which
  sections to include and the document design, then preview, share or save.
- **Eight report types**: complete productivity report, habit progress, habit
  history, statistics, to-do report, focus sessions, monthly summary and yearly
  summary. Each one is built from the local database — no server, no account, no
  connection.
- **Six document themes** that change the real PDF: Executive (white, charcoal,
  muted orange), Midnight (graphite pages, white type, amber), Minimal (plain
  white, grey rules), Aurora (blue and violet), Botanical (soft greens) and
  Custom brand (follows your app accent).
- **A4 report design system**: cover with report identity and creator credit,
  executive summary with calculated statistics, section headings, statistics
  cards, tables, progress bars, a vector activity chart, a 16-week heatmap, and
  a footer with the period and page numbers on every page.
- **Eight date ranges** including a custom range that is validated, swapped when
  entered backwards, and clamped to today.
- **Ten toggleable sections**, so a report contains only what was asked for.
- **Save** through Android's Storage Access Framework, **share** to any app
  through the system share sheet, and **preview** the real PDF with paging and
  zoom.
- Meaningful file names such as `FlowTracker_Monthly_Summary_2026-11.pdf`.

### Notes

- Charts and the heatmap are drawn as vector containers, so they stay sharp when
  printed and add no image weight.
- Fonts are the app's own Figtree, embedded in the document.

## 1.5.0 — creator identity and settings polish

### Changed

- **Creator identity is now Umaiz Sufiyan throughout.** The About screen credits
  read "Created by Umaiz Sufiyan", the developer line shows the name rather than
  a handle, and the app style formerly labelled "Express" is now "Modern" to
  match the Classic / Modern / Minimal wording.
- The profile placeholder was the previous author's name. It is now a neutral
  "You", so a fresh install never presents someone else's name as the user's own.
  The placeholder was dropped from the other locales rather than translated,
  because it was never a translation.

### Fixed

- Removed the last hardcoded occurrence of the previous author's name, which sat
  in the demo-seed test as a profile name. The profile name still defaults to
  empty and stays fully editable, independently of the developer credit.

### Unchanged, on purpose

- "Based on Streak by InlitX" stays on the About screen, in the licence notice,
  in `NOTICE.md` and in `ADDITIONAL_TERMS.md`. The GPL section 7 additional terms
  require that attribution on any work derived from Streak; removing it would
  break the licence this project is distributed under. It is an upstream credit,
  not a creator credit, and it is the only place the name still appears.

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
