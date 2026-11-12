#!/usr/bin/env bash
# Check an Android release keystore before you put it anywhere near GitHub.
#
#   bash tool/verify-keystore.sh flow-tracker-release.jks flow-tracker
#
# It prints what the release workflow will see: the format, the alias, the
# subject and the SHA-256 fingerprint. It never copies the keystore anywhere,
# never prints a password, and works on Linux, macOS and Git Bash for Windows.
#
# You will be prompted for the store password — the same value you will put in
# ANDROID_KEYSTORE_PASSWORD.

set -euo pipefail

KEYSTORE="${1:-}"
ALIAS="${2:-}"

if [ -z "$KEYSTORE" ] || [ -z "$ALIAS" ]; then
  echo "usage: $0 <path-to-keystore.jks> <alias>" >&2
  exit 2
fi

if [ ! -f "$KEYSTORE" ]; then
  echo "error: no file at $KEYSTORE" >&2
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "error: keytool not found. Install a JDK (17 or newer) and try again." >&2
  exit 1
fi

echo "file:     $KEYSTORE"
echo "size:     $(wc -c < "$KEYSTORE" | tr -d ' ') bytes"

# The format matters: PKCS12 silently ignores a separate key password, JKS does
# not. Read the magic bytes rather than asking keytool, which needs the password
# before it will say anything.
magic=$(head -c 4 "$KEYSTORE" | od -An -tx1 | tr -d ' \n')
case "$magic" in
  feedfeed)
    echo "format:   JKS  (store and key passwords may differ)"
    ;;
  30*)
    echo "format:   PKCS12  (the key password must equal the store password)"
    ;;
  *)
    echo "format:   unknown (magic bytes: $magic) — this may not be a keystore"
    ;;
esac

echo
echo "Enter the store password when prompted."
echo

keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" > /tmp/keystore-detail.txt 2>&1 || {
  echo "error: could not read alias '$ALIAS' from this keystore." >&2
  echo "       Either the alias is wrong, or the store password did not match." >&2
  echo "       Nothing was uploaded; fix it and run this again." >&2
  rm -f /tmp/keystore-detail.txt
  exit 1
}

subject=$(grep -m1 'Owner:' /tmp/keystore-detail.txt | sed 's/.*Owner: //')
valid=$(grep -m1 'Valid from:' /tmp/keystore-detail.txt | sed 's/^[[:space:]]*//')
sha_colons=$(grep -m1 'SHA256:' /tmp/keystore-detail.txt | sed 's/.*SHA256: //')
sha=$(printf '%s' "$sha_colons" | tr -d ':' | tr 'A-F' 'a-f')

rm -f /tmp/keystore-detail.txt

echo "alias:    $ALIAS"
echo "subject:  $subject"
echo "validity: $valid"
echo "SHA-256:  $sha_colons"
echo

if printf '%s' "$subject" | grep -qi 'CN=Android Debug'; then
  echo "FAIL: this is the Android debug certificate, not a release identity."
  exit 1
fi

echo "This keystore is usable for a release build."
echo
echo "Secrets to add (values never leave your machine except into GitHub):"
echo "  ANDROID_KEYSTORE_BASE64     <- base64 of this file"
echo "  ANDROID_KEYSTORE_PASSWORD   <- the password you just typed"
echo "  ANDROID_KEY_ALIAS           <- $ALIAS"
echo "  ANDROID_KEY_PASSWORD        <- the same password, unless this is JKS with a separate one"
echo
echo "Encode it with:"
echo "  Linux:  base64 -w0 $KEYSTORE > keystore.b64"
echo "  macOS:  base64 -i $KEYSTORE -o keystore.b64"
echo
echo "The release workflow will print this fingerprint after signing:"
echo "  $sha"
