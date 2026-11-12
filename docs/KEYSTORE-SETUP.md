# Android release keystore — step by step

You need to do this **once, ever**. The keystore becomes the permanent identity of
the app: every future update must be signed with this exact file, or Android
refuses to install it. Treat it like a passport.

Everything below happens on your own computer. Nothing here goes into chat, into
an issue, or into the repository.

---

## 0. Install a JDK

`keytool` ships with Java. Check whether you already have it:

```
keytool -help
```

If that prints "command not found", install a JDK 17 or newer:

- **Windows** — `winget install EclipseAdoptium.Temurin.17.JDK`, then open a **new**
  terminal so `PATH` refreshes.
- **macOS** — `brew install --cask temurin@17`.
- **Linux** — `sudo apt install openjdk-17-jdk-headless` (Debian/Ubuntu) or
  `sudo dnf install java-17-openjdk` (Fedora).

Check it worked with `keytool -help` again.

---

## 1. Pick a folder and one password

Make a folder you will back up, for example `~/flow-tracker-signing/`.

Choose **one** strong password. You will use the same value for both the keystore
and the key, and this matters:

> With the modern **PKCS12** format, `keytool` **silently ignores a different key
> password**. If you type a second, different password and then store that second
> value in `ANDROID_KEY_PASSWORD`, the Gradle build fails with
> "keystore password was incorrect". Using one password for both removes the
> entire failure mode.

Put it in a password manager now. Losing it means you can never update the app
under the same identity.

---

## 2. Generate the keystore

In that folder, run this. Replace the name/org with your own.

**Windows (PowerShell):**

```
keytool -genkeypair -v -keystore flow-tracker-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias flow-tracker -storetype PKCS12
```

**macOS and Linux** — identical command.

`keytool` then asks:

- **Enter keystore password:** your password. It will ask you to retype it.
- **What is your first and last name?** → `Umaiz Sufiyan`
- **Organizational unit / Organization / City / State / Country** → your details,
  e.g. `Flow-tracker`, `Kerala`, `IN`. These appear in the certificate; they do not
  have to be perfect, but they should be honest.
- It prints `Generating 4,096 bit RSA key pair...` and writes
  `flow-tracker-release.jks`.

`-validity 10000` is roughly 27 years — deliberately longer than Google's
requirement that a key stay valid past 22 October 2033.

---

## 3. Check it before you upload anything

Run the checker in this repository:

```
bash tool/verify-keystore.sh flow-tracker-release.jks flow-tracker
```

It prompts for your password and prints the format, alias, subject, validity and
SHA-256 fingerprint. It exits non-zero if the password or alias is wrong, or if
the keystore holds the Android debug certificate. **Write down the SHA-256** —
after the first signed build, the workflow prints the same fingerprint, and the
two must match.

On Windows, run it from Git Bash.

---

## 4. Encode it as base64

GitHub secrets are text, so the binary keystore is base64-encoded first.

- **Linux:** `base64 -w0 flow-tracker-release.jks > keystore.b64`
- **macOS:** `base64 -i flow-tracker-release.jks -o keystore.b64`
- **Windows PowerShell:**
  `[Convert]::ToBase64String([IO.File]::ReadAllBytes("flow-tracker-release.jks")) | Set-Content -NoNewline keystore.b64`

Open `keystore.b64` in a text editor and copy **all** of it — one long line, no
line breaks, no `-----BEGIN` header.

---

## 5. Add the four secrets

Go to the repository → **Settings → Secrets and variables → Actions → New
repository secret**. Add exactly these four names:

| Name | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the whole contents of `keystore.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | your password |
| `ANDROID_KEY_ALIAS` | `flow-tracker` |
| `ANDROID_KEY_PASSWORD` | the **same** password |

Spelling and capitalisation matter — these are matched exactly. No quotes, no
trailing spaces.

If the workflow later says a secret is missing, it is almost always a typo in the
name.

---

## 6. Back up the keystore

Copy `flow-tracker-release.jks` to two places: your password manager (as an
attachment) and offline storage. Not GitHub, not a public drive, not chat.

If it is lost, you cannot update the app under the same identity again — you would
have to publish a new listing with a new application id.

---

## 7. Confirm and build

1. **Actions → Signing check → Run workflow.** It reports the four secrets as
   `configured` and prints the keystore's alias, subject and SHA-256. If the
   fingerprint matches the one from step 3, everything is wired correctly.
2. **Actions → Release → Run workflow** with tag `v1.5.0`, signing `required`,
   scope `android`. It builds the APK and AAB, signs them, verifies the signature
   with `apksigner` and `jarsigner`, and publishes.

The workflow never echoes a secret. If a step fails, it names the credential, not
its value.

---

## Troubleshooting

| Message | Cause |
| --- | --- |
| `refusing to build an unsigned release — missing credentials` | one of the four names is absent or misspelled |
| `the keystore does not open with ANDROID_KEYSTORE_PASSWORD` | wrong password, or the base64 was truncated when pasting |
| `ANDROID_KEY_ALIAS (x) is not in the keystore` | the alias differs — run the checker to see the real one |
| `Keystore was tampered with, or password was incorrect` (Gradle) | `ANDROID_KEY_PASSWORD` differs from the store password on a PKCS12 keystore |
| `this keystore holds the Android DEBUG certificate` | you uploaded `~/.android/debug.keystore` by mistake |
| App won't install over the old one | the installed copy is debug-signed; uninstall it once |
