# Git Workflow & Branching

## Branches
- **`develop`**: Main/default development branch. All day-to-day feature work and PRs target `develop`.
- **`staging`** *(planned)*: Pre-production environment branch promoted from `develop`.
- **`production`** *(planned)*: Live release branch promoted from `staging`.

## Rules for Agents
- Default to `develop` as the base/target branch (do not assume `main` or `master`).
- Never push directly to `develop`, `staging`, or `production`; all changes land via pull requests.
- Never force-push, rewrite shared history, or merge into `staging`/`production` unless explicitly instructed.

## Feature Completion: CI-Gated Auto-Merge

Agents own the delivery loop ([AI Efficiency & Autonomy](AI_EFFICIENCY.md) §5). Do not ask the operator for permission to merge Tier 1–3 work.

1. **Branch**: `<type>/<short-slug>` from an up-to-date `develop` (`feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`).
2. **Verify**: `./scripts/check.sh --quiet` passes, then `critic` returns `PASS` where its tier requires it ([Code Review Policy](REVIEW_POLICY.md)).
3. **Commit & push**: Conventional Commits; `git push -u origin <branch>`.
4. **Open PR** against `develop` with a **Verification Evidence** block (commands, pass counts, runtime proof, `critic` verdict):
   ```bash
   gh pr create --base develop --title "<type>: <summary>" --body "<summary + Verification Evidence>"
   ```
5. **Enable auto-merge** (Tier 1–3 only); GitHub merges once the `check` workflow passes:
   ```bash
   gh pr merge --auto --squash --delete-branch
   ```
   In cloud sessions without `gh`, use the GitHub MCP `enable_pr_auto_merge` tool.
6. **Report** the PR URL; fix and push again if CI fails (counts toward the 2-attempt circuit breaker).

### One-time repository setup (operator)
CI-gated auto-merge needs, under GitHub **Settings**: *General → Allow auto-merge*, and a branch protection rule (or ruleset) on `develop` requiring the `check` status check from [`.github/workflows/check.yml`](../.github/workflows/check.yml). Without the required check, `--auto` either fails or merges immediately with no CI gate.

### Do NOT auto-merge (open the PR, then stop and report the link)
- `critic` verdict is `NEEDS HUMAN SIGN-OFF` (any **Tier 4** critical/high finding or ambiguity: payments, POS/fiscal, auth, security, BYOK secret storage, production deploys).
- Behavioral prompt/agent changes gated by [Agent Improvement & Evals](AGENT_IMPROVEMENT.md).
- Unresolved product ambiguity, or the operator explicitly asked to review before merging.

### When blocked
- If `gh` is missing or unauthenticated, or branch protection requires a human approval the agent cannot give, **do not work around it** (no direct pushes to `develop`, no admin overrides). Push the branch, report the exact blocker, and tell the operator the one-time fix (e.g., `brew install gh && gh auth login`).
