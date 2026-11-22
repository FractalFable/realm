# Model Routing

Model tier policy for implementation, review, and agent-ops work. Concrete model IDs live **only** in this file so upgrading is a single-file change. Agent frontmatter and docs use Claude Code aliases (`haiku`, `sonnet`, `opus`), which always resolve to the latest release of each family.

*Last verified: 2026-11-22*

## Model Ladder

| Alias | Current model ID | Use for |
| :--- | :--- | :--- |
| `opus` | `claude-opus-5-5` | Main session (implementation), Tier 4 `critic`, `security-auditor` |
| `sonnet` | `claude-sonnet-5-5` | Tier 3 `critic`, `doc-writer`, `agent-improver`, unnamed helpers (`Explore`, `general-purpose`) |
| `haiku` | `claude-haiku-5-5` | Tier 2 `critic`, `web-researcher` (read-only, rule-list or digest work) |

## Rules

- **Haiku is read-only only**: never use it to write code, edit policy, or review Tier 3–4 changes.
- **Per-call override**: Callers set the `critic` model per tier via the `Agent` tool's `model` param ([Code Review Policy](REVIEW_POLICY.md)); it beats frontmatter, which beats `CLAUDE_CODE_SUBAGENT_MODEL`.
- **Do not set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`**: it overrides every agent's pinned model and would put Tier 4 review on the default.
- **Quota pressure**: If `opus` is unavailable, drop the main session to `sonnet` but keep Tier 4 `critic` on the strongest available model; if none is available for Tier 4, open the PR and stop for human review.
- **Unknown provider**: On a non-Claude harness, ask the user once which models map to `haiku` / `sonnet` / `opus`.
- **Refresh**: When new releases appear, [`agent-improver`](../.claude/agents/agent-improver.md) verifies them via [`web-researcher`](../.claude/agents/web-researcher.md) and presents an Approval Summary before updating this file.
