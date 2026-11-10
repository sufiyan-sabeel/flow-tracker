# Changelog

All notable changes to Flow-tracker are recorded here. Versions follow
[Semantic Versioning](https://semver.org/), and each release is tagged `vX.Y.Z`.

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
