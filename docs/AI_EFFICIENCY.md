# AI Efficiency & Autonomy

Realm minimizes token usage and quota burn while preserving strict engineering quality through deterministic 0-token checks, context isolation in subagents, and lazy doc reading.

## 1. Zero-Token Deterministic Gate (`./scripts/check.sh`)

Run [`./scripts/check.sh`](../scripts/check.sh) **before** invoking `code-reviewer`:
- Pass `--quiet` (`./scripts/check.sh --quiet`) during iterative checks to emit a single summary line on pass (saving tool-output tokens), or pass a package path (`./scripts/check.sh packages/realm_core`) when testing a single package.
- Never spend LLM tokens finding formatting, lint, broken-link, model-ID placement, workspace `pubspec.yaml`, hardcoded `lib/` URL, or unit-test failures.

## 2. How to Use Subagents to *Save* Tokens (Not Burn Them)

Every subagent spawn has a fixed cold-start cost (~3k–5k tokens), **but** subagents isolate noisy intermediate tool outputs (large `git diff`s, web searches, lockfile scans) so that noise is discarded instead of polluting the main conversation history for every remaining turn:

| Subagent | Delegate When (Saves Context) | Handle Directly in Main Session When (Saves Cold Start) |
| :--- | :--- | :--- |
| [`code-reviewer`](../.agents/agents/code-reviewer.md) | Feature/PR completion or any Tier 3–4 change (keeps full `git diff` out of main context; runs in 1 single pass for `<= 15` files / `<= 500` lines) | Mid-task WIP edits before `./scripts/check.sh` passes |
| [`doc-writer`](../.agents/agents/doc-writer.md) | Multi-file or new-runbook doc work (`> 3` files or `> 80` changed lines) | Small doc syncs (`<= 3` files and `<= 80` lines) + run `./scripts/check_hygiene.py` |
| [`web-researcher`](../.agents/agents/web-researcher.md) | `2+` web searches or package/SDK/model version verification (keeps search snippets out of main chat) | Single trivial fact already verifiable via local CLI/files |
| [`security-auditor`](../.agents/agents/security-auditor.md) | Dependency/CVE audits, `pubspec.lock` upgrades, or SSH server patching | Routine non-security code edits |
| [`agent-improver`](../.agents/agents/agent-improver.md) | **Only** when one of its 5 drift/failure triggers fires ([`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md)) | **Never** spawn on clean runs ("just in case") |

### Subagent Token Rules
- **Self-contained subagents**: `.agents/agents/*.md` contain their own core rules so subagents execute in **1–2 tool turns** without reading `docs/*.md` on startup.
- **Don't double-read diffs**: Let `code-reviewer` read the full `git diff` inside its isolated context instead of dumping a full `git diff` in the main session first.
- **Pass context in the brief**: Include `./scripts/check.sh: PASSED`, changed file list (`git diff --stat`), and today's date in subagent briefs so workers skip discovery.
- **Delta-only re-reviews**: After fixing review findings, pass only the newly touched files + prior findings to `code-reviewer` for a 1-pass delta check.

## 3. Lazy Doc Reading & Context Hygiene

- **Read on demand only**: Never pre-read all of `docs/*.md` at session start. Read only the single doc needed for the active step (see [`AGENTS.md`](../AGENTS.md)).
- **Targeted file reads**: Use `rg`/`grep`, line ranges (`StartLine`/`EndLine`), and Dart MCP (`analyze_files`, `lsp`) instead of reading whole files repeatedly.
- **Session compaction**: Use `/compact` or start a fresh thread per PR so long history does not re-bill input tokens on every turn.

## 4. High-Autonomy Delivery Loop

The operator does not edit code manually. Run end-to-end without pausing unless hitting a Tier 4/human-gate boundary:
1. Implement cleanly per [`docs/PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md) and [`docs/CONFIG_AND_SECRETS.md`](CONFIG_AND_SECRETS.md) (`.dart` edits auto-format via `.agents/hooks.json`).
2. Run `./scripts/check.sh --quiet` and fix any failures automatically.
3. Update docs (inline if `<= 3` files / `<= 80` lines; via `doc-writer` if larger).
4. Run `code-reviewer` once `./scripts/check.sh` passes; fix any `CRITICAL`/`HIGH`/`MEDIUM` findings and run a 1-pass delta re-review.
5. **Open and auto-merge the PR into `develop`** per [`docs/GIT_WORKFLOW.md`](GIT_WORKFLOW.md) and report the merged PR URL—only stop for confirmation on **Tier 4** (`NEEDS HUMAN SIGN-OFF`), SSH/server mutations, destructive git actions, or gated [`docs/AGENT_IMPROVEMENT.md`](AGENT_IMPROVEMENT.md) changes.
