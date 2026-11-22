# Code Review Policy

Large diffs in Realm are reviewed by [`code-reviewer`](../.agents/agents/code-reviewer.md) using **risk-based tiers** mapped to [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md). Lightweight tiers handle low-risk changes (docs, formatting, UI scaffolding), while the highest tiers reserve deep scrutiny for business logic, security, and payments.

## Pre-Review Gate (Zero-Token Deterministic Checks)

Callers must run [`./scripts/check.sh`](../scripts/check.sh) (`dart format --output=none --set-exit-if-changed .`, `dart analyze`, `./scripts/check_hygiene.py`, and package tests) **before** invoking `code-reviewer` and include the passing summary. `code-reviewer` trusts that fresh run instead of re-running tests; if deterministic checks fail, `code-reviewer` returns `REQUEST CHANGES` immediately without spending Tier 3–4 tokens.

## Risk Tiers

| Tier | Risk Level | Typical Paths | Model Assignment | Focus |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | Low | `docs/**` *(except Tier 3–4 policy/security docs)*, `*.md`, `.gitignore`, `scripts/check.sh`, static assets, formatting-only diffs | Tier 1 (Lowest) in `MODEL_ROUTING.md` | Clarity, valid links, root `AGENTS.md` lean-index rule, zero fixed venue brands or external test-project mentions, no accidental secrets |
| **Tier 2** | Standard | `packages/realm_ui/**`, `**/widgets/**`, `**/screens/**`, `**/theme/**`, `**/views/**`, `packages/realm_lints/**`, non-critical UI tests | Tier 2 (Low-Mid) in `MODEL_ROUTING.md` | Strict brand-agnostic rule (no fixed venue names/colors or hardcoded URLs in `lib/`, no raw BYOK secrets in clients), responsive/a11y basics, widget lifecycle/const/disposal |
| **Tier 3** | High | `packages/realm_core/**`, `**/bloc/**`, `**/cubit/**`, `**/services/**`, `**/repositories/**`, `**/server/**`, `**/db/**`, `pubspec.yaml`, `pubspec.lock`, `docs/REVIEW_POLICY.md`, `docs/MODEL_ROUTING.md`, `.agents/agents/**` *(except `security-auditor.md`)* | Tier 3 (High-Mid) in `MODEL_ROUTING.md` | Domain invariants, edge cases, concurrency/races, backward-compatible migrations, error handling, test coverage, white-label/BYOK isolation |
| **Tier 4** | Critical | `**/payment*/**`, `**/billing/**`, `**/checkout/**`, `**/pos/**`, `**/fiscal*/**`, `**/auth/**`, `**/security/**`, `**/crypto/**`, `docs/CONFIG_AND_SECRETS.md`, `scripts/deploy*`, `compose.production*`, `.agents/agents/security-auditor.md` | Tier 4 (Highest) in `MODEL_ROUTING.md` (+ human sign-off on Critical/High findings or ambiguity) | Adversarial audit: idempotency, integer-cents/rounding safety, double-charge prevention, authz bypass, token/session handling, BYOK secret storage (backend-only, encrypted at rest, never logged/returned unmasked), injection, rollback safety |

*(See [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md) for current Gemini/Claude model IDs, minimum floor rules, and the unknown-provider fail-safe.)*

## Promotion & Routing Rules

1. **Content overrides path**: If a file in a lower-risk path (e.g., a UI widget or doc/script) touches payments, fiscalization, authentication, authorization, secrets/BYOK keys, or financial math, promote that file to **Tier 3** or **Tier 4** immediately.
2. **Small diffs (`<= 15` files and `<= 500` changed lines) or single-tier diffs**: Review in **1 single pass** at the highest active tier's model from [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md) (no subagent fan-out).
3. **Large multi-tier diffs**: Triage at **Tier 1** and cap fan-out at **2 parallel buckets** (Tier 1–2 combined + Tier 3–4 combined)—never spawn a subagent for 1–2 small files. Trigger the fail-safe question if the active provider/models are unrecognized.
4. **Delta-only re-reviews**: After fixes, inspect only files touched since the prior pass alongside the prior findings list in **1 single pass** without re-fanning out unchanged tiers.

## Review Verdicts

Every review returns one of four verdicts:
- **`APPROVE`** — No blocking issues found.
- **`APPROVE WITH NOTES`** — Safe to merge/commit; minor non-blocking `LOW` suggestions noted (never overrides Tier 4's mandatory human sign-off below).
- **`REQUEST CHANGES`** — Must fix listed `CRITICAL` / `HIGH` / `MEDIUM` bugs or regressions first.
- **`NEEDS HUMAN SIGN-OFF`** — Mandatory whenever **Tier 4** has any `CRITICAL`/`HIGH` finding, unresolved ambiguity, or touches live payment, fiscal, secret-storage, or production deployment logic requiring operator review (superseding `APPROVE WITH NOTES`).

## Severity Levels & Fix Routing

1. **Severity tagging**: Every finding is tagged and sorted `CRITICAL` → `HIGH` → `MEDIUM` → `LOW`.
2. **Blocking threshold**: Any `CRITICAL`, `HIGH`, or `MEDIUM` finding triggers `REQUEST CHANGES` (or `NEEDS HUMAN SIGN-OFF` in Tier 4). Outside Tier 4's mandatory sign-off cases, `LOW`-only findings produce `APPROVE WITH NOTES` so minor nits do not force extra review cycles.
3. **Which model makes fixes**: `code-reviewer` is strictly read-only and hands findings back to the calling agent. Route fixes proportionally to risk using [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md):
   - **Mechanical / Tier 1–2 fixes** (`docs`, formatting, lints, simple UI/tests): handled autonomously at **Tier 1–2**.
   - **Tier 3–4 fixes** (domain invariants, state/concurrency, backend/DB, auth, security, payments): designed and applied at **Tier 3–4**, then verified via `./scripts/check.sh` and re-reviewed afterwards.
