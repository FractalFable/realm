# Git Workflow & Branching

## Branches
- **`develop`**: Main/default development branch. All day-to-day feature work and PRs target `develop`.
- **`staging`** *(planned)*: Pre-production environment branch promoted from `develop`.
- **`production`** *(planned)*: Live release branch promoted from `staging`.

## Rules for Agents
- Default to `develop` as the base/target branch (do not assume `main` or `master`).
- Never push directly to `develop`, `staging`, or `production`; all changes land via pull requests.
- Never force-push, rewrite shared history, or merge into `staging`/`production` unless explicitly instructed.

## Feature Completion: Auto-Merge via Pull Request

Agents own the full delivery loop. When a feature is complete, **open and merge the PR autonomously — do not ask the operator for permission to merge.**

1. **Branch**: Start work on `<type>/<short-slug>` from an up-to-date `develop` (`feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`).
2. **Verify**: `./scripts/check.sh` passes, then `code-reviewer` returns `APPROVE` or `APPROVE WITH NOTES` (fix and delta re-review any blocking findings first; see [Code Review Policy](REVIEW_POLICY.md)).
3. **Commit & push**: Conventional Commit messages (`feat: ...`, `fix: ...`); `git push -u origin <branch>`.
4. **Open PR** against `develop` with a summary, verification output, and review verdict:
   ```bash
   gh pr create --base develop --title "<type>: <summary>" --body "<summary, check.sh result, review verdict>"
   ```
5. **Wait for CI** (if any checks are configured): `gh pr checks --watch`. Fix failures and push again.
6. **Merge & clean up**:
   ```bash
   gh pr merge --squash --delete-branch
   git checkout develop && git pull --ff-only
   ```
7. **Report** the merged PR URL in the final summary.

### Do NOT auto-merge (open the PR, then stop and report the link)
- `code-reviewer` verdict is `NEEDS HUMAN SIGN-OFF` (any **Tier 4** critical/high finding or ambiguity: payments, POS/fiscal, auth, security, BYOK secret storage, production deploys).
- Behavioral prompt/agent changes gated by [Agent Improvement & Evals](AGENT_IMPROVEMENT.md).
- Unresolved product ambiguity, or the operator explicitly asked to review before merging.

### When blocked
- If `gh` is missing or unauthenticated, or branch protection requires a human approval the agent cannot give, **do not work around it** (no direct pushes to `develop`, no admin overrides). Push the branch, report the exact blocker, and tell the operator the one-time fix (e.g., `brew install gh && gh auth login`).
