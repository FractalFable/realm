# AI Efficiency & Autonomy

Realm keeps strong models on high-risk work (see [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md)) while reducing token usage, latency, and human interruptions through deterministic tooling, tight context hygiene, and smart agent-calling boundaries.

## 1. Deterministic Gate Before AI Review

Run [`./scripts/check.sh`](../scripts/check.sh) **before** invoking `code-reviewer`:
- Checks `dart format --output=none --set-exit-if-changed .`, `dart analyze`, and `dart test` / `flutter test` across every workspace package.
- Never spend LLM tokens discovering formatting nits, lint errors, missing imports, or broken unit tests.

## 2. Context & Tool Hygiene

- **Keep root [`AGENTS.md`](../AGENTS.md) lean**: only link out to `docs/`; scope app-specific rules inside `apps/<app>/AGENTS.md`.
- **Keep MCPs opt-in**: only enable MCP servers needed for the active task ([`docs/AGENT_SETUP.md`](AGENT_SETUP.md)).
- **Use targeted reads & tools**: search with `rg`/`grep`, read targeted line ranges, and use Dart MCP (`analyze_files`, `lsp`) instead of dumping large files into context.
- **Keep source files modular**: aim for focused files (`~100–250` lines) so agents read and edit cheaply with fewer retries.
- **Session hygiene**: run `/compact` or start a fresh thread per milestone/PR so long chat history does not multiply input tokens on every turn.

## 3. Agent-Calling & Subagent Efficiency

Every subagent spawn pays a full cold-start cost (system prompt, tool schemas, `AGENTS.md`, and repo discovery). Minimize spawns and redundant work:
- **Avoid micro-subagents**: For diffs of `<= 15` files (or `<= 500` changed lines), run **1 single `code-reviewer`** at the highest active tier instead of fanning out per tier.
- **Cap multi-tier fan-out at 2 buckets**: On large multi-tier diffs, group into at most **2 parallel buckets** (Tier 1–2 combined + Tier 3–4 combined)—never spawn a dedicated subagent for 1–2 small files.
- **Delta-only re-reviews**: After fixes, pass only the files changed since the prior pass plus the previous findings list and verify in **1 single pass** without re-fanning out unchanged tiers.
- **Trust fresh `./scripts/check.sh` results**: Caller runs `./scripts/check.sh` once and reports the passing output; `code-reviewer` does not re-run tests inside child reviewers.
- **Single-pass batched docs**: Route all `README.md` and `docs/` updates to [`doc-writer`](../.agents/agents/doc-writer.md) in **one batched pass** at the end of a feature (Tier 1).

## 4. High-Autonomy Execution Defaults

The repository owner does not edit code manually. Unless blocked by a **Tier 4** security/payment/production boundary or genuine product ambiguity, agents should run end-to-end without pausing mid-task:
1. Plan & implement cleanly following `docs/PROJECT_OVERVIEW.md` and `docs/CONFIG_AND_SECRETS.md`.
2. Run `dart format .` and `./scripts/check.sh` (fixing any mechanical format/lint/test failures automatically).
3. Batch any needed doc updates via `doc-writer` (`Tier 1`).
4. Run `code-reviewer` once the feature is complete and `./scripts/check.sh` passes.
5. Fix any blocking `CRITICAL` / `HIGH` / `MEDIUM` review findings and re-verify (delta-only re-review) before reporting back.
6. Only ask the user for confirmation on: **Tier 4** changes (payments, POS/fiscal, auth, security, production deploys), SSH/server mutations, destructive git/data actions, or behavioral prompt changes gated by [`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md).
