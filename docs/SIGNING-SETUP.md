# Signing setup, step by step

This is the beginner's guide. `docs/SIGNING.md` is the reference — what each
secret is and what the pipeline does with it. This file is the *how*: what to buy,
what to run, where to click.

Read the whole thing once before starting. The Android keystore is the one step
you cannot undo, so do that one carefully.

> **Never paste a private key, password or `.p12` into chat, an issue, or a commit.**
> Everything below stays on your machine and goes straight into GitHub Secrets.

---

## 0. What "signing" actually means

A signature is a mathematical stamp that proves two things: *this file came from
you*, and *nobody changed it after you built it*.

- **Android** — a keystore holds your private key. Every APK you ship is signed
  with it. If a future update is signed with a *different* key, Android refuses to
  install it. This is why the keystore must never be regenerated.
- **iOS / macOS** — Apple issues you a certificate tied to your developer team.
  Without it, iOS won't install the app and macOS shows "unidentified developer".
- **Windows** — a certificate authority (CA) vouches that you are the publisher, so
  SmartScreen can attribute the file to a name instead of "unknown publisher".
- **Linux** — there is no central authority. You publish a GPG public key and sign
  the packages with the matching private key; users import your key and verify.

The pipeline verifies every signature with the platform's own tool before it
publishes anything. If a signature is wrong, the release stops.

---

## 1. Android — the keystore (do this first, and back it up)

You need Java installed (`keytool` ships with it).

```bash
keytool -genkeypair -v \
  -keystore flow-tracker-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias flow-tracker -storetype JKS
```

It asks for a store password, a key password, and your name/org. Use a long
random password from a password manager.

Then produce the value for GitHub:

```bash
base64 -w0 flow-tracker-release.jks > keystore.b64     # Linux
base64 -i flow-tracker-release.jks -o keystore.b64     # macOS
```

**Back up `flow-tracker-release.jks` in at least two places** — a password manager
attachment plus offline storage. If you lose it, you can never update the app
under the same identity; you would have to publish a new listing.

The four secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | contents of `keystore.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | the store password |
| `ANDROID_KEY_ALIAS` | `flow-tracker` |
| `ANDROID_KEY_PASSWORD` | the key password |

The pipeline prints the certificate's SHA-256 at preflight and then refuses to
publish an APK signed by anything else — so the identity is checked, not assumed.

---

## 2. iOS — Apple Distribution certificate

You need a paid **Apple Developer Program** membership (99 USD/year,
[developer.apple.com/programs](https://developer.apple.com/programs/)). A free
account cannot produce a distribution certificate.

1. In the [developer portal](https://developer.apple.com/account), go to
   **Certificates, Identifiers & Profiles → Certificates** and create an
   **Apple Distribution** certificate. You will upload a Certificate Signing
   Request (CSR), which Keychain Access generates: *Certificate Assistant →
   Request a Certificate From a Certificate Authority*.
2. Download the `.cer`, double-click it to add it to your keychain.
3. In **Keychain Access**, find the certificate, expand it, select both the
   certificate *and* its private key, right-click → **Export 2 items** → save as
   `distribution.p12` with a password.
4. Under **Profiles**, create an **App Store** provisioning profile for the bundle
   id `com.flowtracker.app`, and download the `.mobileprovision`.
5. Your Team ID is shown at the top right of the developer portal.

```bash
base64 -w0 distribution.p12 > ios-cert.b64
base64 -w0 FlowTracker_AppStore.mobileprovision > ios-profile.b64
```

| Secret | Value |
| --- | --- |
| `IOS_CERT_P12_BASE64` | `ios-cert.b64` |
| `IOS_CERT_PASSWORD` | password you set when exporting the `.p12` |
| `IOS_PROVISION_PROFILE_BASE64` | `ios-profile.b64` |
| `IOS_TEAM_ID` | your 10-character team id |

---

## 3. macOS — two certificates and notarization

Same Apple Developer membership, but **two different certificate types**:

- **Developer ID Application** — signs the `.app` and the `.dmg`.
- **Developer ID Installer** — signs the `.pkg`.

Create both in the portal the same way as the iOS certificate, then export each
from Keychain Access as its own `.p12`.

Notarization needs an **app-specific password**: go to
[appleid.apple.com](https://appleid.apple.com) → *Sign-In and Security* →
*App-Specific Passwords* → generate one. Do not use your real Apple ID password.

| Secret | Value |
| --- | --- |
| `MACOS_CERT_P12_BASE64` | Developer ID **Application** `.p12`, base64 |
| `MACOS_CERT_PASSWORD` | its export password |
| `MACOS_INSTALLER_P12_BASE64` | Developer ID **Installer** `.p12`, base64 |
| `MACOS_INSTALLER_PASSWORD` | its export password |
| `MACOS_TEAM_ID` | your team id |
| `MACOS_NOTARY_APPLE_ID` | your Apple ID email |
| `MACOS_NOTARY_PASSWORD` | the app-specific password |

---

## 4. Windows — Authenticode

This is the step people get stuck on, so read it fully.

Buy a **code signing certificate** from a CA — DigiCert, Sectigo, SSL.com, GlobalSign
and others sell them. Budget roughly 200–600 USD/year depending on OV vs EV.

**The important caveat:** since June 2023 the CA/Browser Forum requires private keys
for OV and EV code signing certificates to live on FIPS 140-2 hardware or a
compliant cloud HSM. Many CAs therefore ship a **USB token** or a **cloud signing
service** rather than a downloadable `.pfx`.

- If your CA gives you a **`.pfx` you can export**, use it: convert to base64 and
  set the two secrets below. This is what the pipeline currently expects.
- If your CA gives you a **token or cloud HSM** (DigiCert KeyLocker, SSL.com eSigner,
  Azure Trusted Signing), you cannot produce a `.pfx`. The signing step needs to
  call that provider's signing tool instead of `signtool /f`. That is a workflow
  change, not a secret — open an issue and it can be adapted, or use **Azure Trusted
  Signing**, which Microsoft designed for CI.

| Secret | Value |
| --- | --- |
| `WINDOWS_PFX_BASE64` | your `.pfx`, base64 encoded |
| `WINDOWS_PFX_PASSWORD` | the `.pfx` password |

Signing removes "unknown publisher". It does **not** grant SmartScreen reputation —
that accrues with download volume over weeks. Expect a warning on a brand-new
certificate.

---

## 5. Linux — GPG

Free, and takes five minutes.

```bash
gpg --full-generate-key          # RSA 4096, no expiry, your real name and email
gpg --list-secret-keys --keyid-format=long    # note the key id
gpg --armor --export-secret-keys <KEY_ID> | base64 -w0 > gpg.b64
```

| Secret | Value |
| --- | --- |
| `GPG_PRIVATE_KEY_BASE64` | `gpg.b64` |
| `GPG_PASSPHRASE` | the key's passphrase |
| `GPG_KEY_ID` | the key id or full fingerprint |

Publish the fingerprint in your README so users can confirm the key they import is
yours. The pipeline attaches the public key to the release automatically.

---

## 6. Put the secrets into GitHub

Go to **Settings → Environments → New environment**, name it exactly `release`.
Then add protection rules:

- **Required reviewers** — add yourself. Now every production build waits for a
  human click before it can use the credentials.
- **Deployment branches and tags** — restrict to tags matching `v*`.

Then **Settings → Secrets and variables → Actions → New repository secret** for
each of the twenty names above. Paste the value only — no quotes, no `export`, no
trailing newline.

If a name is misspelled, preflight will list it as missing, which is exactly what
you want: nothing gets built with a half-configured identity.

---

## 7. Run a production release

```bash
# bump the version first, and update RELEASE_TAG in .github/workflows/release.yml
git tag v1.5.0
git push origin v1.5.0
```

A tag push can **only** run the signed path. What happens:

1. **preflight** checks the tag matches `pubspec.yaml`, checks all twenty secrets
   are present, runs the tests, and reads the Android certificate fingerprint.
2. Each platform builds, signs, and verifies with its own tool.
3. **publish** runs only if all five succeeded, and the release notes carry a
   signing table.

To rehearse without publishing, use **Actions → Release → Run workflow** with
`signing: unsigned`. That produces a clearly-labelled unsigned build instead.

---

## 8. When something fails

| Message | Meaning |
| --- | --- |
| `refusing to build an unsigned release — missing credentials:` | one or more secrets are absent or misnamed; the list is in the summary |
| `is signed with the debug key — refusing to publish` | `android/key.properties` was not written, so Gradle fell back to debug |
| `is not signed by the expected certificate` | the keystore in secrets is not the one that produced the APK |
| `IPA is not signed with an Apple Distribution certificate` | you exported a Development certificate instead |
| `PKG is not signed by Developer ID Installer` | the Installer certificate is missing from `MACOS_INSTALLER_P12_BASE64` |
| `notarytool` fails | wrong app-specific password, or the certificate is not a Developer ID |
| `signature verification failed for …` (Windows) | the `.pfx` is expired, or the private key is not exportable |
| `gpg: BAD signature` | the private key does not match the public key you published |

Each of these is the verification step doing its job. The fix is always the
credential, never the check.

---

## 9. What you still own

- The **keystore file** and its passwords. Nobody can regenerate them for you.
- Renewal dates for the Apple membership and the Windows certificate.
- Keeping the GPG private key safe and the public fingerprint published.

The pipeline never stores any of these — it reads them from secrets at build time,
uses them, and deletes the temporary copies at the end of the job.
