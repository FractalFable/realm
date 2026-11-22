# AI Efficiency & Autonomy

Realm keeps strong models on high-risk work (see [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md)) while reducing token usage, latency, and human interruptions through deterministic tooling, tight context hygiene, and smart agent-calling boundaries.

## 1. Deterministic Gate Before AI Review

Run [`./scripts/check.sh`](../scripts/check.sh) **before** invoking `code-reviewer`:
- Checks `dart format --output=none --set-exit-if-changed .`, `dart analyze`, [`./scripts/check_hygiene.py`](../scripts/check_hygiene.py) (relative links, model-ID single source, workspace `pubspec.yaml` + no legacy `genui`, no hardcoded `lib/` URLs), and `dart test --reporter=failures-only` / `flutter test --reporter=failures-only` (quiet on pass).
- Never spend LLM tokens discovering formatting nits, lint errors, broken links, missing imports, or broken unit tests.

## 2. Context & Tool Hygiene

- **Keep root [`AGENTS.md`](../AGENTS.md) lean**: only link out to `docs/`; scope app-specific rules inside `apps/<app>/AGENTS.md`.
- **Keep MCPs opt-in**: only enable MCP servers needed for the active task ([`docs/AGENT_SETUP.md`](AGENT_SETUP.md)).
- **Use targeted reads & tools**: search with `rg`/`grep`, read targeted line ranges, and use Dart MCP (`analyze_files`, `lsp`) instead of dumping large files into context.
- **Keep source files modular**: aim for focused files (`~100–250` lines) so agents read and edit cheaply with fewer retries.
- **Session hygiene**: run `/compact` or start a fresh thread per milestone/PR so long chat history does not multiply input tokens on every turn.

## 3. Agent-Calling & Subagent Efficiency

Every subagent spawn pays a full cold-start cost (system prompt, tool schemas, `AGENTS.md`, and repo discovery). Minimize spawns and redundant work:
- **Delegation threshold & tier pinning**: Apply tiny doc syncs (`<= 2` files / `< 30` lines) or single quick `search_web` lookups directly in the active session instead of paying a subagent cold start. Batch substantial doc updates to [`doc-writer`](../.agents/agents/doc-writer.md) (pinning Tier 1 via `swarm` when the coordinator is on Tier 3–4) and multi-source research (`3+` queries) to `web-researcher`.
- **Context handoff**: Pass pre-computed `git diff --stat`, changed file list, active tier, and fresh `./scripts/check.sh` output in subagent briefs so workers skip redundant discovery and test runs.
- **Avoid micro-subagents**: For diffs of `<= 15` files **and** `<= 500` changed lines, run **1 single `code-reviewer`** at the highest active tier instead of fanning out per tier.
- **Cap multi-tier fan-out at 2 buckets**: On large multi-tier diffs, group into at most **2 parallel buckets** (Tier 1–2 combined + Tier 3–4 combined)—never spawn a dedicated subagent for 1–2 small files.
- **Exclude diff noise**: Omit `pubspec.lock`, `*.g.dart`, and `*.freezed.dart` from full review diffs (inspect lockfiles via summary only when auditing dependencies).
- **Delta-only re-reviews**: After fixes, pass only the files changed since the prior pass plus the previous findings list and verify in **1 single pass** without re-fanning out unchanged tiers.
- **Trust fresh `./scripts/check.sh` results**: Caller runs `./scripts/check.sh` once and reports the passing output; `code-reviewer` does not re-run tests inside child reviewers.

## 4. High-Autonomy Execution Defaults

The repository owner does not edit code manually. Unless blocked by a **Tier 4** security/payment/production boundary or genuine product ambiguity, agents should run end-to-end without pausing mid-task:
1. Plan & implement cleanly following `docs/PROJECT_OVERVIEW.md` and `docs/CONFIG_AND_SECRETS.md`.
2. Run `dart format .` and `./scripts/check.sh` (fixing any mechanical format/lint/test failures automatically).
3. Batch any needed doc updates via `doc-writer` (`Tier 1`).
4. Run `code-reviewer` once the feature is complete and `./scripts/check.sh` passes.
5. Fix any blocking `CRITICAL` / `HIGH` / `MEDIUM` review findings and re-verify (delta-only re-review) before reporting back.
6. **Open and merge the PR into `develop` autonomously** once checks and review pass, then report the merged PR URL — never ask "should I merge?" (see [`docs/GIT_WORKFLOW.md`](GIT_WORKFLOW.md) for the exact flow and no-auto-merge exceptions).
7. Only ask the user for confirmation on: **Tier 4** changes (payments, POS/fiscal, auth, security, production deploys), SSH/server mutations, destructive git/data actions (force-push, history rewrites, merges into `staging`/`production`), or behavioral prompt changes gated by [`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md).
