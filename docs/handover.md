# Handover

Updated: 2026-10-11

All 620 locked npm tarballs use the official registry. Versions and integrity
hashes are unchanged. Node 24 type definitions were added to remove a missing
type warning. CI runs the existing lint, Svelte type check, production
build, and browser tests through the root justfile. Draft PRs skip these checks
and run when marked ready.

`just check` passed: zero lint findings, zero Svelte errors/warnings, a production
build, and two real Chromium tests. The accessibility test reproduced the
unnamed-link defect before the fix. `BUN_INSTALL_CACHE_DIR=/path/to/empty/cache
just install-fresh` verifies dependency acquisition independently of the cache.
