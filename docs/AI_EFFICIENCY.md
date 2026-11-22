# AI Efficiency & Autonomy

Autonomous execution, verification, and self-improvement protocol. Goal: nothing merges unverified, while LLM tokens go only where risk justifies them. Deterministic checks cost 0 tokens, so they always run first.

## 1. Classify Before Acting

Pick one tier from the [Code Review Policy](REVIEW_POLICY.md) path table before running tools (content overrides path; highest file tier wins):

| Tier | Examples | Deterministic gate | Runtime proof | `critic` | Merge |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** Low | Docs, styles, small single-file edits | Yes | Skip | Skip | Auto (CI-gated) |
| **2** Standard | UI widgets, theming, standard fixes | Yes | Affected flow | `haiku`, only if `>= 3` files | Auto (CI-gated) |
| **3** High | `realm_core` domain, shared DTOs, deps, agent config | Yes | Affected flow | `sonnet`, always | Auto (CI-gated) |
| **4** Critical | Payments/fiscal, auth, E2EE/key derivation, BYOK storage, DB migrations, prod deploy | Yes | Full | `opus`, always | **Human sign-off** |

## 2. Execution & Verification Loop

Work on a branch from `develop` (see [Git Workflow](GIT_WORKFLOW.md)); never commit to `develop` directly.

1. **Reproduce first (bugs only)**: Write a failing test before editing source and note the exact failure output. Keep it as a permanent regression test.
2. **Minimal changes**: Targeted edits, not full-file rewrites. Never weaken or delete test assertions to get green.
3. **Deterministic gate (hard gate)**: `./scripts/check.sh --quiet` (format, `dart analyze --fatal-infos`, hygiene, `--reporter=failures-only` tests; pass a package path to scope tests). One summary line on pass, full errors on failure. Nothing below runs until it exits `0`. When touching entrypoints, also run the app's build command (e.g. `flutter build web`) and require exit `0`.
4. **Runtime proof (Tier 2–4)**: Prove the affected flow actually works, then stop background processes:
   - **Packages** (today's scope): widget/unit tests in `check.sh` are the proof (light + dark, `>= 2` `VenueBranding` seeds).
   - **Flutter apps**: `integration_test` or Dart MCP `flutter_driver_command` / `widget_inspector` with `get_runtime_errors` empty ([Testing & Debugging](TESTING_AND_DEBUGGING.md) §3). Do **not** use Playwright on Flutter UIs: Flutter Web renders to a canvas, so DOM selectors do not see widgets.
   - **Backend REST**: `curl` or test-client assertions on status codes and response schemas.
   - **Non-Flutter web apps**: Playwright MCP, zero console errors.
5. **`critic` review** per the tier table: brief = goal, tier, `check.sh: PASSED`, `git diff --stat`, truncated verification output (last `<= 30` lines). `critic` reads the diff itself, so never dump a full diff into the main session.

## 3. Circuit Breaker (Anti-Spin)

- **Max 2 fix attempts** per failing check or `critic` FAIL. Re-reviews are delta-only (touched files + prior findings).
- Still failing after 2 attempts: **stop**. Report what failed, the last 20 lines of error output, and what you tried. Open no PR (or leave it as draft).

## 4. Self-Improvement (Only on Friction)

Skip entirely on clean first-pass runs.

- **Lightweight (no subagent)**: On a non-obvious build flag, environment quirk, or recurring mistake, append one rule (`<= 3` lines) under `## Learned Constraints` in [`CLAUDE.md`](../CLAUDE.md), or to the relevant `.claude/skills/` file.
- **Heavyweight**: Changes to agent prompts, routing, or review policy go through [`agent-improver`](../.claude/agents/agent-improver.md) (A/B track + approval gate), only when one of its 5 triggers fires ([Agent Improvement](AGENT_IMPROVEMENT.md)).

## 5. Commit, PR & Merge

1. Conventional commit (`feat:`, `fix:`, `chore:`, `docs:`).
2. Push and open a PR against `develop` with a **Verification Evidence** block: exact commands run, test pass counts, runtime/API proof, and the `critic` verdict (or `skipped: Tier 1`). No vague prose.
3. Tier 1–3: enable CI-gated auto-merge (`gh pr merge --auto --squash`, or `enable_pr_auto_merge` via GitHub MCP). Tier 4: leave open for human sign-off.
4. End the final response with a one-line reminder to run `/clear` before an unrelated task.

## 6. Token Rules

| Subagent (model) | Delegate when | Handle directly when |
| :--- | :--- | :--- |
| [`critic`](../.claude/agents/critic.md) (tiered) | Per the tier table | Tier 1, or Tier 2 with `< 3` files |
| [`doc-writer`](../.claude/agents/doc-writer.md) (`sonnet`) | `> 3` doc files or `> 80` changed lines | Smaller doc syncs + `./scripts/check_hygiene.py` |
| [`web-researcher`](../.claude/agents/web-researcher.md) (`haiku`) | `2+` searches or version verification | One fact checkable via local CLI/files |
| [`security-auditor`](../.claude/agents/security-auditor.md) (`opus`) | Dependency/CVE audits, lockfile upgrades, SSH patching | Routine non-security edits |
| [`agent-improver`](../.claude/agents/agent-improver.md) (`sonnet`) | One of its 5 triggers fires | **Never** on clean runs |

- **Main session** implements on the strongest model: first-pass quality avoids retries, which cost more than the model difference.
- **Unnamed helpers** (`Explore`, `general-purpose`) default to `sonnet` via `CLAUDE_CODE_SUBAGENT_MODEL` in [`.claude/settings.json`](../.claude/settings.json); named agents pin their own `model` in frontmatter, which takes precedence.
- **Lazy reads**: Never pre-read `docs/*.md`; use `rg`/`grep`, line-ranged reads, and Dart MCP (`analyze_files`) over repeated whole-file reads.
- **Fresh context**: `/clear` (or a new session) per unrelated task; `/compact` in long ones.
