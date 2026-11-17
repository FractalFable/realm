# Git Workflow & Branching

## Branches
- **`develop`**: Main/default development branch. All day-to-day feature work and PRs target `develop`.
- **`staging`** *(planned)*: Pre-production environment branch promoted from `develop`.
- **`production`** *(planned)*: Live release branch promoted from `staging`.

## Rules for Agents
- Default to `develop` as the base/target branch (do not assume `main` or `master`).
- Never push directly to `staging` or `production` unless explicitly instructed.
