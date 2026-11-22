# Agent Improvement & Evals

[`agent-improver`](../.claude/agents/agent-improver.md) maintains `.claude/**` and agent-ops policy docs using evidence and strict anti-bloat discipline.

## Scope & Ownership Split

- **`agent-improver` owns**: `.claude/**` and agent-ops policy docs ([`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md), [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md), [`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md)).
- **[`doc-writer`](../.claude/agents/doc-writer.md) owns**: `README.md`, `AGENTS.md`, `**/AGENTS.md`, and general `docs/*.md` (edit directly when `<= 3` files and `<= 80` lines; spawn `doc-writer` for larger doc work).
- **Never modifies**: `apps/` or `packages/`.

## Lightweight Path (No Subagent)

For a one-off trap (build flag, environment quirk, recurring mistake), append one rule (`<= 3` lines) under `## Learned Constraints` in [`CLAUDE.md`](../CLAUDE.md) directly. Use `agent-improver` only for changes to agent prompts, routing, or review policy.

## Strict Trigger Rules (Never Spawn on Clean Runs)

Invoke `agent-improver` **only** when one of these 5 events occurs during a task:
1. User corrects an agent's behavior, convention, or model/quota usage.
2. `critic` finds a recurring defect pattern or false positive.
3. A build, lint, SDK, or setup command fails due to stale docs/prompts.
4. A new app, package, stack, or MCP server causes doc/agent drift.
5. Model catalog availability or quota shifts require updating [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md).

*If normal feature work succeeds cleanly, do **not** invoke `agent-improver`.*

## Two Tracks

1. **Fast Track (Factual / Compression / Syncs — Tier 1)**:
   - Objective updates: SDK/model table updates, link fixes, CLI command adjustments, or prompt token compression that preserves all invariants.
   - Verify via files, `./scripts/check_hygiene.py`, or [`web-researcher`](../.claude/agents/web-researcher.md) (no A/B eval needed).
2. **A/B Track (Behavioral Prompt / Policy Changes — Tier 3)**:
   - Define pass/fail rubric upfront (target fix, non-regression on baseline, conciseness).
   - Run **Variant A (Control)** vs. **Variant B (Candidate via a temporary `Agent` call with the candidate prompt)** on identical input and model.
   - **Promote only strict wins** with zero regressions and no added bloat.

## Summary Approval Gate

Wait for explicit user approval (presenting `Trigger`, `Track & Score`, `Target Files`, and `2–4 Summary Bullets`) before mutating:
- Behavioral prompts/rules via the **A/B Track**,
- [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md) or [`.claude/agents/agent-improver.md`](../.claude/agents/agent-improver.md),
- [`docs/CONFIG_AND_SECRETS.md`](CONFIG_AND_SECRETS.md), [`.claude/agents/security-auditor.md`](../.claude/agents/security-auditor.md), or Tier 4 rules in [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md) / [`.claude/agents/critic.md`](../.claude/agents/critic.md).

## Experiment Log

| Date | Target | Hypothesis | Benchmark | A vs B | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 2026-11-22 | `.agents/**`, `docs/*`, `scripts/check*`, `CLAUDE.md`, `AGENTS.md` | Quiet `--reporter=failures-only`, deterministic hygiene gate, lazy doc reads, Tier 1 pinning, and prompt de-duplication cut cold-start and per-turn tokens without weakening Tier 1–4 guardrails | Repo-wide token & policy audit (user-approved direct rollout) | Baseline 59.7 KB / mandatory turn-1 reads → lean lazy prompts + 0-token hygiene gate | Accepted |
| 2026-11-22 | `.agents/agents/*`, `docs/*`, `AGENTS.md`, `scripts/*` | Self-contained 0-doc-read subagents, trimmed tool schemas, Argon quota fallback, `--quiet` check.sh, and fast-path hook cut subagent turns and context size ~35% while isolating diff/search noise | Repo-wide token & subagent efficiency overhaul (user-approved) | 76.7 KB total / multi-read subagents → self-contained 1-pass subagents + quiet gate | Accepted |
| 2026-11-22 | `.claude/**`, `.mcp.json`, `.github/workflows/check.yml`, `docs/*`, `AGENTS.md`, `CLAUDE.md`, `scripts/*` | Port agents/hook to Claude Code; one tiered `critic` (haiku → sonnet → opus by risk) replaces the single-model reviewer; 2-retry circuit breaker and Learned Constraints keep review and self-improvement cheap | Claude Code readiness audit + user-supplied protocol (user-approved) | Antigravity-only agents/hook (inactive in Claude Code) → native `.claude/` config + CI-gated auto-merge | Accepted |
