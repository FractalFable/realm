# Code Review Policy

Agents review each other's work through one read-only subagent, [`critic`](../.claude/agents/critic.md). Review depth and model scale with risk so cheap changes cost nothing and critical ones get the strongest model plus a human.

## Pre-Review Gate (0 LLM Tokens)

Run [`./scripts/check.sh --quiet`](../scripts/check.sh) (format, `dart analyze --fatal-infos`, hygiene, package tests) **before** `critic` and pass `check.sh: PASSED` in the brief. `critic` never re-runs it and ignores anything it enforces.

## Risk Tiers

| Tier | Risk | Typical Paths | Focus |
| :--- | :--- | :--- | :--- |
| **Tier 1** | Low | `docs/**` *(non-Tier 3/4)*, `*.md`, `.gitignore`, `scripts/check*`, formatting diffs | Clarity, valid links, lean root `AGENTS.md`, zero fixed venue brands or external project names, no secrets |
| **Tier 2** | Standard | `packages/realm_ui/**`, `**/widgets/**`, `**/screens/**`, `**/theme/**`, `packages/realm_lints/**`, UI tests | Brand-agnostic theming (`VenueBranding`), no hardcoded `lib/` URLs or client secrets, `ValueKey` + `Semantics`, light/dark tests, widget disposal |
| **Tier 3** | High | `packages/realm_core/**`, `**/bloc/**`, `**/cubit/**`, `**/services/**`, `**/repositories/**`, `**/server/**`, `**/db/**`, `pubspec.*`, `.claude/**`, `.mcp.json`, `.github/workflows/**`, `docs/REVIEW_POLICY.md`, `docs/MODEL_ROUTING.md` | Domain invariants, edge cases, concurrency/races, reversible migrations, error handling, failure-path tests |
| **Tier 4** | Critical | `**/payment*/**`, `**/billing/**`, `**/checkout/**`, `**/pos/**`, `**/fiscal*/**`, `**/auth/**`, `**/security/**`, `**/crypto/**`, `docs/CONFIG_AND_SECRETS.md`, `scripts/deploy*`, `compose.production*`, `.claude/agents/security-auditor.md`, `**/migrations/**`, `**/e2ee/**`, key derivation | Adversarial audit: integer-cents/rounding, idempotency/double-charge, authz, AAD-bound AEAD BYOK encryption, masked `keyHint` (`>= 16` chars), injection, rollback safety (+ human sign-off) |

## Review Routing by Tier

| Tier | `critic` | Model (pass as the `Agent` `model` param) | Merge |
| :--- | :--- | :--- | :--- |
| **1** | Skip | — | CI-gated auto-merge |
| **2** | Only if `>= 3` files changed | `haiku` (frontmatter default) | CI-gated auto-merge |
| **3** | Always | `sonnet` | CI-gated auto-merge |
| **4** | Always | `opus` | **No auto-merge**: open PR, `NEEDS HUMAN SIGN-OFF` |

**Why scale the model**: a review reads one diff and writes `<= 15` lines, so even the top model costs a fraction of the implementation. Haiku is reliable for rule-list checks (Tier 2) but misses subtle logic, concurrency, and crypto defects, where one escaped bug costs far more than the review.

## Routing & Token Rules

1. **Content overrides path**: Any file touching payments, fiscalization, authn/authz, E2EE/key handling, BYOK secrets, DB migrations, or financial math promotes to **Tier 4**; shared client/server models (DTOs) promote to **Tier 3**.
2. **Highest tier wins**: A multi-file diff is reviewed at the tier of its riskiest file, in **1 single pass** (no fan-out). Split diffs `> 15` files or `> 500` lines into smaller PRs instead of fanning out reviewers.
3. **Diff stays in the critic**: `critic` runs `git diff` itself; the caller sends only the goal, tier, file list (`git diff --stat`), and truncated verification output.
4. **Delta-only re-reviews, max 2**: After a FAIL, fix, re-run `check.sh --quiet`, and send only the touched files + prior findings. After the 2nd FAIL, stop and report (circuit breaker).

## Verdicts

- **`PASS`** — merge per the tier table.
- **`FAIL`** — any `CRITICAL`/`HIGH`/`MEDIUM` finding; fix and delta re-review (max 2).
- **`NEEDS HUMAN SIGN-OFF`** — appended on every Tier 4 review; open the PR and stop.
