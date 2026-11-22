# Code Review Policy

[`code-reviewer`](../.agents/agents/code-reviewer.md) reviews diffs using **risk-based tiers** mapped to [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md), isolating raw `git diff` noise inside the reviewer subagent while reserving deep scrutiny for business logic, auth, and payments.

## Pre-Review Gate (0 LLM Tokens)

Callers must run [`./scripts/check.sh`](../scripts/check.sh) (`dart format`, `dart analyze`, `./scripts/check_hygiene.py`, and package tests) **before** invoking `code-reviewer` and pass `check.sh: PASSED` in the brief. `code-reviewer` never re-runs passing tests.

## Risk Tiers

| Tier | Risk | Typical Paths | Focus |
| :--- | :--- | :--- | :--- |
| **Tier 1** | Low | `docs/**` *(non-Tier 3/4)*, `*.md`, `.gitignore`, `scripts/check*`, formatting diffs | Clarity, valid links, lean root `AGENTS.md`, zero fixed venue brands or external project names, no secrets |
| **Tier 2** | Standard | `packages/realm_ui/**`, `**/widgets/**`, `**/screens/**`, `**/theme/**`, `packages/realm_lints/**`, UI tests | Brand-agnostic theming (`VenueBranding`), no hardcoded `lib/` URLs or client secrets, `ValueKey` + `Semantics`, light/dark tests, widget disposal |
| **Tier 3** | High | `packages/realm_core/**`, `**/bloc/**`, `**/cubit/**`, `**/services/**`, `**/repositories/**`, `**/server/**`, `**/db/**`, `pubspec.*`, `.agents/**`, `docs/REVIEW_POLICY.md`, `docs/MODEL_ROUTING.md` | Domain invariants, edge cases, concurrency/races, reversible migrations, error handling, failure-path tests |
| **Tier 4** | Critical | `**/payment*/**`, `**/billing/**`, `**/checkout/**`, `**/pos/**`, `**/fiscal*/**`, `**/auth/**`, `**/security/**`, `**/crypto/**`, `docs/CONFIG_AND_SECRETS.md`, `scripts/deploy*`, `compose.production*`, `.agents/agents/security-auditor.md` | Adversarial audit: integer-cents/rounding, idempotency/double-charge, authz, AAD-bound AEAD BYOK encryption, masked `keyHint` (`>= 16` chars), injection, rollback safety (+ human sign-off) |

## Routing & Token Rules

1. **Content overrides path**: Any file touching payments, fiscalization, authn/authz, BYOK secrets, or financial math promotes to **Tier 3** or **Tier 4**.
2. **Single-pass default (`<= 15` files and `<= 500` changed lines)**: Review in **1 single pass** inside `code-reviewer` (zero child subagent fan-out).
3. **Large multi-tier diffs (`> 15` files or `> 500` lines)**: Cap fan-out at **2 parallel buckets** (`Bucket A: Tier 1–2`, `Bucket B: Tier 3–4`). Exclude `pubspec.lock`, `*.g.dart`, and `*.freezed.dart` from raw diffs.
4. **Delta-only re-reviews**: After fixes, inspect only the newly modified files + prior findings in **1 pass**.

## Verdicts & Severity Routing

- **`APPROVE`** — No issues found.
- **`APPROVE WITH NOTES`** — Non-blocking `LOW` suggestions only (auto-merge eligible outside Tier 4 sign-off).
- **`REQUEST CHANGES`** — Any `CRITICAL`, `HIGH`, or `MEDIUM` finding; caller must fix, run `./scripts/check.sh --quiet`, and run a delta re-review.
- **`NEEDS HUMAN SIGN-OFF`** — Mandatory when **Tier 4** has any `CRITICAL`/`HIGH` finding, ambiguity, or touches live payment, fiscal, secret-storage, or production deploy logic (open PR, do **not** auto-merge).
