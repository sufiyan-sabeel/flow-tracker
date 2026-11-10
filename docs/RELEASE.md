# Releasing Flow-tracker

Everything in this document is what the repository actually does. If a platform
is unsigned here, it is unsigned in the release notes too.

## What exists

| Platform | Runner | Artifacts | Signing in CI |
| --- | --- | --- | --- |
| Android | `ubuntu-latest` | APK per ABI, AAB | release keystore if secrets exist, otherwise debug key (the log says which) |
| iOS | `macos-latest` | unsigned IPA | none — needs your team's certificate and profile |
| Windows | `windows-latest` | Inno Setup EXE, MSI | none — SmartScreen will warn |
| Linux | `ubuntu-latest` | AppImage, DEB | unsigned is normal |
| macOS | `macos-latest` | DMG, PKG | unsigned, not notarized |

Two workflows:

- `.github/workflows/ci.yml` — formatting, analysis and the full test suite on
  every push and pull request. Fast feedback; no artifacts.
- `.github/workflows/release.yml` — validates the version, re-runs the checks,
  builds all five platforms in parallel, verifies every artifact, then publishes
  one release with `SHA256SUMS.txt`.

## Cutting a release

1. Bump the version in `pubspec.yaml`, for example `version: 1.9.0+11`. The part
   before `+` is the release name; the part after is the Android version code and
   must increase on every release.
2. Update `CHANGELOG.md` with a section for the new version.
3. Commit and push to `main`.
4. Tag the same commit and push the tag:

   ```bash
   git tag v1.9.0
   git push origin v1.9.0
   ```

5. Watch the **Release** workflow. The `validate` job fails immediately if the
   tag and `pubspec.yaml` disagree, which is the usual cause of a red run.
6. When all five platform jobs are green, `publish` creates the release and
   attaches the verified artifacts.

A failed platform fails the run and nothing is attached for it. There is no path
where the release claims a build that did not happen.

To re-run without a new tag, use **Actions → Release → Run workflow** and give it
the existing tag.

## Secrets

All optional. Without them the builds still run, unsigned, and the release notes
say so.

| Secret | Used by | What it does |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Android | base64 of your `.jks`; enables a real release signature |
| `ANDROID_KEYSTORE_PASSWORD` | Android | keystore password |
| `ANDROID_KEY_PASSWORD` | Android | key password |
| `ANDROID_KEY_ALIAS` | Android | key alias |

Add them under **Settings → Secrets and variables → Actions**. Never commit a
keystore, `key.properties`, or a password. `android/.gitignore` already excludes
them.

For signed iOS and notarized macOS builds you also need an Apple Developer
account, a distribution certificate, a provisioning profile and App Store Connect
credentials. None of that is configured here; adding it is a separate task and
the workflow is structured so it can be added without touching the build steps.

## Artifact names

```
Flow-Tracker-<version>-Android-arm64-v8a.apk
Flow-Tracker-<version>-Android-armeabi-v7a.apk
Flow-Tracker-<version>-Android-x86_64.apk
Flow-Tracker-<version>-Android.aab
Flow-Tracker-<version>-iOS-unsigned.ipa
Flow-Tracker-<version>-Windows-x64.exe
Flow-Tracker-<version>-Windows-x64.msi
Flow-Tracker-<version>-Linux-x86_64.AppImage
Flow-Tracker-<version>-Linux-amd64.deb
Flow-Tracker-<version>-macOS-universal.dmg
Flow-Tracker-<version>-macOS-universal.pkg
```

Architecture labels come from the actual build target: Android splits by ABI,
Windows and Linux build x64, macOS builds the default architecture of the runner.

## What each build actually runs

- **Android** — `flutter build apk --release --split-per-abi`,
  `flutter build appbundle --release`. Verified: `classes.dex` present, a
  `libapp.so` for the ABI in the file name, and the package id read out of the
  binary manifest equals `com.flowtracker.app`.
- **iOS** — `pod install`, `flutter build ios --release --no-codesign`, then the
  `.app` is zipped into `Payload/` to form an IPA. Verified: the IPA contains
  `Payload/Runner.app/Runner`, and its bundle id and short version match the
  release.
- **Windows** — `flutter build windows --release`, then Inno Setup
  (`windows/installer/flow_tracker.iss`) for the EXE and WiX `heat` + `candle` +
  `light` for the MSI. Both package the entire release folder, not just the
  executable. Verified: both files exist, are over 1 MB, and the MSI references
  the app binary.
- **Linux** — `flutter build linux --release`, then a hand-assembled `dpkg-deb`
  package and an AppImage built with `appimagetool` 1.9.0. Verified: the DEB
  contains `opt/flow-tracker/flow-tracker`, its control metadata is readable, and
  the AppImage is an ELF binary.
- **macOS** — `pod install`, `flutter build macos --release`, `hdiutil` for the
  DMG, `pkgbuild` for the PKG. Verified: `hdiutil verify` passes and the PKG
  payload contains the app binary.

## Known limitations

- iOS and macOS artifacts are unsigned. The IPA cannot be installed on a device
  without re-signing; the macOS app needs right-click → Open the first time.
- Windows installers are unsigned, so SmartScreen warns.
- No physical iPhone or Mac was used to test these builds. Compiling and
  packaging on a GitHub runner is not the same as installing on a device.
- Home-screen widgets and scheduled reminders are Android/iOS features; the
  desktop builds run without them.
- The macOS project was generated for this release; its plugins build, but the
  desktop UI has not been exercised by hand.
