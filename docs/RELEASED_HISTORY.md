# Released history and the 2026-11-11 correction

This file records what was published, what was removed, and what pointed where.
It exists because a release correction deleted GitHub Releases and remote tags,
and that removal should never be invisible to whoever reads this repository next.

No commit was deleted and no branch was touched. Every commit that any removed
tag pointed at is still reachable from `main`; the code those releases contained
is part of the 1.5.0 release.

## What was removed on 2026-11-11

### GitHub Releases deleted

| Release | Release id | Tag | Tag commit | Assets removed |
| --- | --- | --- | --- | --- |
| Flow-tracker v1.6.0 | 440533582 | `v1.6.0` | `50c1c2825fb32248990d9d58afdd93dc86d6fe55` | `Flow-tracker-arm64-v8a.apk` (47.10 MB, sha256 `8235466385d1904798936b4bb9924fac9c304187a7c2689cef3ecb7c0c21553c`), `Flow-tracker-armeabi-v7a.apk` (45.92 MB), `Flow-tracker-x86_64.apk` (48.52 MB), `SHA256SUMS.txt` |
| Flow-tracker v1.7.0 | 440649351 | `v1.7.0` | `18105bd537948be082cd3c146cc2f88b499078ef` | `Flow-tracker-arm64-v8a.apk` (47.35 MB, sha256 `bbdbf094a7fecdf1ff384265ed630c83977e995f5becf22c97853b048ea3bdc2`), `Flow-tracker-armeabi-v7a.apk` (46.21 MB), `Flow-tracker-x86_64.apk` (48.85 MB), `SHA256SUMS.txt` |

Both were Android-only releases. Neither satisfied the multi-platform release
requirement, and neither was the intended version.

### Remote tags deleted

| Tag | Commit it pointed at | Why |
| --- | --- | --- |
| `v1.6.0` | `50c1c2825fb32248990d9d58afdd93dc86d6fe55` | incorrect version |
| `v1.7.0` | `18105bd537948be082cd3c146cc2f88b499078ef` | incorrect version |
| `v1.8.0` | `a64ca39d89a634bac03c2480149a79c9724416a1` | never released; deleted so a stray tag could not publish a version that is not the target |

## The v1.5.0 tag

`v1.5.0` existed before this correction and pointed at
`c3cc0e1f90564c6160f3eb5e1e11ae16e5a44849` — the creator-identity release, which
was Android-only. It has been re-pointed at the corrected multi-platform commit
for this release. The previous target is recorded above so nothing is lost.

## What was kept

- `v1.0.0` … `v1.4.0` releases and tags are untouched.
- `main` is untouched as a branch; no force-push, no history rewrite.
- The source changes from the development versions 1.6.0 through 1.8.0 ship in
  this release; see `CHANGELOG.md`.
