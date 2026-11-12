#!/usr/bin/env python3
"""Static audit of the release signing configuration.

This exists because the dangerous failure mode for a signing pipeline is not a
crash — it is a *quiet* mismatch: a secret used by a build step but missing from
the preflight gate, a credential documented but never used, or a path that lets a
tag push publish something unsigned.

Runs on every push in CI. No dependencies beyond the standard library.

    python3 tool/check_signing.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = ROOT / ".github/workflows/release.yml"
DOCS = ROOT / "docs/SIGNING.md"

failures: list[str] = []
notes: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def note(message: str) -> None:
    notes.append(message)


def secrets_used(text: str) -> set[str]:
    """Every `secrets.NAME` the workflow interpolates."""
    return set(re.findall(r"secrets\.([A-Z][A-Z0-9_]+)", text))


def secrets_gated(text: str) -> set[str]:
    """Every secret the preflight credential gate actually checks.

    The gate is a run block of the form:

        check ANDROID_KEYSTORE_BASE64 "${ANDROID_KEYSTORE_BASE64:-}"
    """
    return set(re.findall(r"^\s*check\s+([A-Z][A-Z0-9_]+)\s", text, re.MULTILINE))


def secrets_documented(text: str) -> set[str]:
    """Every secret listed in a table row of docs/SIGNING.md."""
    return set(re.findall(r"^\|\s*`([A-Z][A-Z0-9_]+)`\s*\|", text, re.MULTILINE))


def main() -> int:
    if not WORKFLOW.exists():
        print(f"::error::missing {WORKFLOW}")
        return 1
    if not DOCS.exists():
        print(f"::error::missing {DOCS}")
        return 1

    workflow = WORKFLOW.read_text(encoding="utf-8")
    docs = DOCS.read_text(encoding="utf-8")

    used = secrets_used(workflow)
    gated = secrets_gated(workflow)
    documented = secrets_documented(docs)

    # 1. every secret used must be checked by the preflight gate
    for name in sorted(used - gated):
        fail(f"secret {name} is used by a build step but not checked in the preflight gate")

    # 2. every secret the gate checks must actually be used
    for name in sorted(gated - used):
        fail(f"preflight checks {name} but no step uses it")

    # 3. docs and workflow must agree in both directions
    for name in sorted(used - documented):
        fail(f"secret {name} is used in the workflow but not documented in docs/SIGNING.md")
    for name in sorted(documented - used):
        fail(f"docs/SIGNING.md documents {name} but the workflow never uses it")

    # 4. no debug key may be accepted as a production identity
    if "CN=Android Debug" not in workflow:
        fail("the APK verification does not reject the debug signing certificate")
    else:
        debug_checks = re.findall(
            r'if \[ "\$\{SIGNING_MODE\}" = "required" \][^\n]*\n(?:[^\n]*\n){0,3}?[^\n]*CN=Android Debug',
            workflow,
        )
        if not debug_checks:
            fail("the debug-certificate rejection is not guarded by production mode")

    # 5. there must be no silent keystore fallback
    if re.search(r"signingConfig\s*=\s*signingConfigs\.getByName\(\"debug\"\)", workflow):
        fail("the workflow configures a debug signing config")

    # 6. a tag push must never be able to select the unsigned mode
    mode = re.search(r"SIGNING_MODE:\s*(.+)", workflow)
    if not mode:
        fail("SIGNING_MODE is not defined")
    else:
        expression = mode.group(1).strip()
        if "github.event.inputs.signing" not in expression:
            fail(
                "SIGNING_MODE does not derive from github.event.inputs.signing, so a tag "
                f"push could select a non-production mode (got: {expression})"
            )
        if "'required'" not in expression and '"required"' not in expression:
            fail(f"SIGNING_MODE has no 'required' default (got: {expression})")

    # 7. the release notes must not interpolate secrets
    if "body: |" in workflow:
        for block in workflow.split("body: |")[1:]:
            body = block.split("\n      - name:")[0]
            if re.search(r"secrets\.[A-Z]", body):
                fail("a release body interpolates a secret value")

    # 8. production publishing must be gated on every platform
    publish = re.search(r"\n  publish:\n(.*?)(?:\n  [a-z_]+:\n|\Z)", workflow, re.S)
    if not publish:
        fail("no publish job found")
    else:
        block = publish.group(1)
        for platform in ("android", "ios", "windows", "linux", "macos"):
            if platform not in block:
                fail(f"the publish job does not depend on {platform}")
        if "success()" not in block:
            fail("the publish job is not gated on success()")

    # 9. signing jobs must sit behind the protected environment
    signing_jobs = ["android", "ios", "windows", "linux", "macos"]
    for job in signing_jobs:
        job_block = re.search(rf"\n  {job}:\n(.*?)(?:\n  [a-z_]+:\n|\Z)", workflow, re.S)
        if job_block and "environment: release" not in job_block.group(1):
            fail(f"the {job} job does not declare the protected `release` environment")

    # 10. verification tools must actually be invoked
    for tool, platform in (
        ("apksigner verify", "Android APK"),
        ("jarsigner -verify", "Android AAB"),
        ("codesign --verify", "iOS/macOS"),
        ("pkgutil --check-signature", "macOS PKG"),
        ("spctl --assess", "macOS Gatekeeper"),
        ("signtool verify", "Windows"),
        ("gpg --verify", "Linux"),
    ):
        if tool not in workflow:
            fail(f"{platform} verification is missing ({tool!r} not found)")

    print(f"secrets used: {len(used)}")
    print(f"secrets gated in preflight: {len(gated)}")
    print(f"secrets documented: {len(documented)}")
    print()
    for name in sorted(used):
        print(f"  {name}")

    if failures:
        print()
        for message in failures:
            print(f"::error::{message}")
        print(f"\n{len(failures)} problem(s) found")
        return 1

    print("\nsigning configuration is consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
