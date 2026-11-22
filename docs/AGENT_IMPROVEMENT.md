# Agent Improvement & Evals

[`agent-improver`](../.agents/agents/agent-improver.md) maintains repository documentation, rules, skills, and custom agent definitions proactively using evidence rather than blind prompt edits.

## Allowed Scope & Ownership Split

- **`agent-improver` owns**: `.agents/**` (agents, skills, hooks) and agent-ops policy docs ([`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md), [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md), and this file [`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md)).
- **[`doc-writer`](../.agents/agents/doc-writer.md) owns**: general repository documentation and READMEs (`README.md`, `**/README.md`, `AGENTS.md`, `**/AGENTS.md`, and general `docs/*.md`). Batch multi-file or substantive doc updates via `doc-writer` at Tier 1 (tiny `<= 2` file / `< 30` line syncs may be applied directly).
- **Must never modify**: application or package code under `apps/` or `packages/`.

## Autonomous Triggers (When to Run vs. Skip)

Main agents should proactively invoke `agent-improver` (and `agent-improver` should self-assess before proposing edits):

- **Run automatically when**:
  1. The user corrects an agent's behavior, convention, or model choice.
  2. `code-reviewer` finds a recurring defect class or produces a false positive / policy gap.
  3. A build, lint, SDK, or setup command fails because repository docs or prompts are stale or missing.
  4. A new app, package, stack, or MCP server is added and existing docs/agents drift.
  5. Newer Gemini/Claude models appear in the active model catalog (or listed models in [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md) become deprecated/unavailable).
- **Skip (do NOT run) when**:
  - Normal feature work succeeds cleanly with no friction, user corrections, or doc drift.
  - The issue is a one-off typo or purely task-specific instruction.

## Two Improvement Tracks & Model Routing

Follow [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md) (referencing Tier 1–4 dynamically from that single source of truth, including the unknown-provider fail-safe; never use legacy Flash/Haiku). Delegate fresh SDK, package, and model-release checks to [`web-researcher`](../.agents/agents/web-researcher.md) rather than relying on training memory:

1. **Fast Track (Factual Updates)** — **Tier 1** in `MODEL_ROUTING.md`
   - For objective, verifiable facts: SDK version bumps, broken links, updated CLI commands, typos, or brand-hygiene doc syncs.
   - Verify against files, command output, or `web-researcher`; no A/B test needed.
   - **High-autonomy rule**: Straightforward factual doc fixes can be batched and applied autonomously when low-risk (summarizing what was updated at the end of the task). `MODEL_ROUTING.md` refreshes, self-edits to `agent-improver.md`, and Tier 4 / security doc edits require waiting for explicit user approval first.
2. **A/B Track (Behavioral Changes)** — **Tier 3** in `MODEL_ROUTING.md`
   - For prompt rewrites, policy/rule changes, or skill adjustments meant to improve reasoning, catch more bugs, or cut false positives.
   - **Never ship blind edits**: prove the candidate beats the baseline with an A/B test first.

## A/B Testing Protocol ("Improve Only")

1. **Define Benchmark & Rubric Upfront**
   - Pick a concrete case (an actual past failure, git diff, or edge-case prompt).
   - Write an objective pass/fail rubric before running anything:
     - Target improvement (did the change fix the specific failure?).
     - Non-regression baseline check (at least one normal case that previously passed).
     - Efficiency / conciseness (did it stay focused without unnecessary bloat or noise?).
2. **Run Control (A) vs. Candidate (B)**
   - Run **Variant A (Control)** using the current agent/doc and **Variant B (Candidate)** using a temporary `define_subagent` (or isolated `Workspace: "branch"` if files are touched).
   - Both variants must receive the **exact same input** and run on the **same model** (respecting `docs/MODEL_ROUTING.md`) so only the instructions differ.
3. **Promote Only Strict Wins**
   - Score both outputs against the rubric.
   - **Keep B only if it strictly beats A with zero regressions.** On a tie, regression, or added bloat, discard B and keep A untouched.
4. **Anti-Bloat Rule**
   - Prefer tightening, clarifying, or replacing weak instructions over appending extra paragraphs.

## Summary Approval Gate

- `agent-improver` runs on its own through diagnosis, `web-researcher` verification, benchmark selection, and isolated A/B testing without interrupting normal coding.
- **Present one concise Approval Summary and wait for user approval before mutating live files** whenever changing:
  - Behavioral prompts/skills/rules via the **A/B Track**,
  - [`docs/MODEL_ROUTING.md`](MODEL_ROUTING.md),
  - [`.agents/agents/agent-improver.md`](../.agents/agents/agent-improver.md) (self-edits),
  - [`docs/CONFIG_AND_SECRETS.md`](CONFIG_AND_SECRETS.md), [`.agents/agents/security-auditor.md`](../.agents/agents/security-auditor.md), or Tier 4 security/payment rules in [`docs/REVIEW_POLICY.md`](REVIEW_POLICY.md) / [`.agents/agents/code-reviewer.md`](../.agents/agents/code-reviewer.md).
- Format:
  - **Trigger**: What prompted the improvement.
  - **Track & Rubric Score**: Fast Track, or A/B Track score (`A` vs. `B`).
  - **Target Files**: Exact files to update.
  - **Summary of Changes**: 2–4 concise bullets explaining what changed and why.
- Once approved, apply the live changes and append a row to the **Experiment Log** below.

## Experiment Log

| Date | Target | Hypothesis | Benchmark | A vs B | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 2026-11-22 | `.agents/**`, `docs/*`, `scripts/check*`, `CLAUDE.md`, `AGENTS.md` | Quiet `--reporter=failures-only`, deterministic hygiene gate, lazy doc reads, Tier 1 pinning, and prompt de-duplication cut cold-start and per-turn tokens without weakening Tier 1–4 guardrails | Repo-wide token & policy audit (user-approved direct rollout) | Baseline 59.7 KB / mandatory turn-1 reads → lean lazy prompts + 0-token hygiene gate | Accepted |
