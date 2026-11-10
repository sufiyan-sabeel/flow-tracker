# Contributing to Flow-tracker

Thanks for wanting to help. This is a small, deliberately focused app, so the
most useful contributions are bug reports, translations and small, well-scoped
fixes.

## Before you start

- Flow-tracker is a fork of [Streak](https://github.com/InlitX/streak). Please
  do not send Flow-tracker issues or pull requests to the upstream project.
- Open an issue describing the problem before a large change, so we can agree on
  the approach first.
- This project is GPL-3.0. By contributing you agree your work is released under
  the same licence, with the additional terms in `ADDITIONAL_TERMS.md`.

## Setting up

```bash
flutter pub get
flutter run
```

Use Flutter 3.41.9 and Java 17 to match CI.

## Checks that must pass

```bash
flutter analyze   # no issues
flutter test      # everything green
```

The CI runs both before it builds anything, so a pull request that fails either
will not be merged. Please do not weaken or delete a test to make it pass — if a
test is wrong, say why in the pull request.

## Style

- Match the surrounding code. The interface, navigation and visual language are
  intentionally close to upstream; avoid redesigns in a bug-fix pull request.
- `prefer_single_quotes`, trailing commas and explicit return types are enforced
  by `analysis_options.yaml`.
- New user-facing strings go in `lib/l10n/app_en.arb`; other languages fall back
  to English until someone translates them.
- New behaviour needs a test in `test/`.

## Translations

Add or edit keys in `lib/l10n/app_<locale>.arb`. English is the template. Keep
`Flow-tracker` untranslated as the product name, and leave placeholders like
`{path}` exactly as they are.

## Reporting a bug

Include the phone model, Android version, app version, and the steps that
triggered it. A screen recording helps more than a description.
