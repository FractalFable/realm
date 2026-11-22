# Code Review Policy

Large diffs in Realm are reviewed by the [`code-reviewer`](../.agents/agents/code-reviewer.md) agent using **risk-based tiers** so lightweight models handle low-risk changes (docs, formatting, UI scaffolding) and stronger models focus deeply on business logic, security, and payments.

## Risk Tiers & Model Routing

| Tier | Risk Level | Typical Paths | Antigravity Model | Claude Code Model | Focus |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | Low | `docs/**`, `*.md`, `.gitignore`, static assets, formatting-only diffs | `flash_lite` | `haiku` | Clarity, valid links, root `AGENTS.md` lean-index rule, no accidental secrets |
| **Tier 2** | Standard | `packages/realm_ui/**`, `**/widgets/**`, `**/screens/**`, `**/theme/**`, `**/views/**`, `packages/realm_lints/**`, non-critical UI tests | `flash` | `sonnet` | White-label branding compliance (no hardcoded venue names/colors), responsive/a11y basics, widget lifecycle/const/disposal, clean state wiring |
| **Tier 3** | High | `packages/realm_core/**`, `**/bloc/**`, `**/cubit/**`, `**/services/**`, `**/repositories/**`, `**/server/**`, `**/db/**`, `pubspec.yaml`, `pubspec.lock` | `pro` | `sonnet` / `opus` | Domain invariants, edge cases, concurrency/races, backward-compatible migrations, error handling, test coverage, white-label/BYOK isolation |
| **Tier 4** | Critical | `**/payment*/**`, `**/billing/**`, `**/checkout/**`, `**/pos/**`, `**/fiscal*/**`, `**/auth/**`, `**/security/**`, `**/crypto/**`, `scripts/deploy*`, `compose.production*`, `.agents/agents/security-auditor.md` | `pro` (+ human sign-off on Critical/High findings or ambiguity) | `opus` (+ human sign-off) | Adversarial audit: idempotency, integer-cents/rounding safety, double-charge prevention, authz bypass, token/session handling, BYOK secret exposure, injection, rollback safety |

## Promotion & Routing Rules

1. **Content overrides path**: If a file in a lower-risk path (e.g., a UI widget or doc/script) touches payments, fiscalization, authentication, authorization, secrets/BYOK keys, or financial math, promote that file to **Tier 3** or **Tier 4** immediately.
2. **Single-tier diff**: Main agents invoke `code-reviewer` directly with that tier's `Model` (`flash_lite`, `flash`, or `pro`).
3. **Multi-tier or large diff**: Main agents invoke `code-reviewer` with `Model: "flash"` as a lightweight triage orchestrator. It classifies the changed files into Tiers 1–4 and spawns parallel `self` subagents using each tier's designated `Model`.

## Review Verdicts

Every review returns one of four verdicts:
- **`APPROVE`** — No blocking issues found.
- **`APPROVE WITH NOTES`** — Safe to merge/commit; minor non-blocking suggestions noted.
- **`REQUEST CHANGES`** — Must fix listed Critical/High/Medium bugs or regressions first.
- **`NEEDS HUMAN SIGN-OFF`** — Mandatory whenever **Tier 4** has any Critical/High finding, unresolved ambiguity, or touches live payment/fiscal/production deployment logic requiring operator review.
