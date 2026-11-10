# Provenance and attribution

Flow-tracker is a derivative work. This file records exactly what it is derived
from and which notices carry over.

## Upstream

| | |
| --- | --- |
| Project | Streak |
| Author | InlitX |
| Source | https://github.com/InlitX/streak |
| Commit this fork started from | `c7b680d312dca4697219c8a96bd8f35003870158` |
| Licence | GNU General Public License, version 3 only, plus the section 7 additional terms in `ADDITIONAL_TERMS.md` |

Copyright in the upstream code and assets remains with InlitX. Nothing in this
repository transfers it.

## Attribution notice

In accordance with Article 2 of `ADDITIONAL_TERMS.md`, the following notice is
displayed wherever the app shows its legal notices — in the app itself on the
About screen, and here in the documentation:

> Based on Streak by InlitX

## Retained documents

These files are retained unmodified, as Article 4 of the additional terms
requires:

- `LICENSE` — the verbatim GNU GPL v3 text
- `ADDITIONAL_TERMS.md` — the section 7 additional terms

## What the fork changed

- Renamed the product to **Flow-tracker**; new app name, package id
  (`com.flowtracker.app`), launcher icon, adaptive icon, monochrome icon and
  splash screen.
- Replaced product-name strings, links and store metadata with Flow-tracker's.
  Habit-domain wording ("current streak", "best streak") is unchanged, because
  that is what the word means in this app.
- Added a true-black AMOLED theme option and its tests.
- Fixed a navigation-rail brand row that overflowed with a longer product name.
- Replaced the release pipeline with a single Android workflow that builds,
  tests, signs, checksums and publishes the APKs.
- Removed upstream distribution configuration that does not apply to this
  project: `fastlane/` store metadata, the `fdroid/` build recipe, the desktop
  and iOS CI workflows, and the old marketing screenshots.

Everything else — the interface, navigation, feature set and data model — is
upstream's work, kept as it was.

## Contact

Flow-tracker: https://github.com/sufiyan-sabeel/flow-tracker/issues

Upstream: https://github.com/InlitX/streak
