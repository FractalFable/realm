#!/usr/bin/env bash
set -euo pipefail

# Deterministic pre-review quality gate.
# Run from anywhere inside the repo before invoking code-reviewer.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Checking formatting..."
dart format --output=none --set-exit-if-changed .

echo "==> Running workspace static analysis..."
dart analyze

echo "==> Running deterministic hygiene checks..."
./scripts/check_hygiene.py

run_tests_in() {
  local dir="$1"
  [[ -f "$dir/pubspec.yaml" && -d "$dir/test" ]] || return 0

  if grep -qE '^[[:space:]]*sdk:[[:space:]]*flutter([[:space:]]|$)' "$dir/pubspec.yaml"; then
    echo "==> Running flutter test in $dir..."
    (cd "$dir" && flutter test --reporter=failures-only)
  else
    echo "==> Running dart test in $dir..."
    (cd "$dir" && dart test --reporter=failures-only)
  fi
}

for pkg_dir in packages/* apps/*; do
  [[ -d "$pkg_dir" ]] || continue
  run_tests_in "$pkg_dir"
done

echo "==> All deterministic checks passed!"
