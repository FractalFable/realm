#!/usr/bin/env bash
set -euo pipefail

# Deterministic pre-review quality gate.
# Usage:
#   ./scripts/check.sh                     # Full workspace check
#   ./scripts/check.sh --quiet             # Single-line output on success (prints full errors on failure)
#   ./scripts/check.sh [--quiet] <pkg_dir> # Scoped test run for one package + workspace format/analyze/hygiene

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

QUIET=0
TARGETS=()
for arg in "$@"; do
  case "$arg" in
    -q|--quiet) QUIET=1 ;;
    *) TARGETS+=("$arg") ;;
  esac
done

run_step() {
  local label="$1"
  shift
  if [[ "$QUIET" -eq 1 ]]; then
    local out
    if ! out="$("$@" 2>&1)"; then
      echo "FAILED: $label" >&2
      printf '%s\n' "$out" >&2
      return 1
    fi
  else
    echo "==> $label"
    "$@"
  fi
}

run_step "Checking formatting..." dart format --output=none --set-exit-if-changed .
run_step "Running workspace static analysis..." dart analyze
run_step "Running deterministic hygiene checks..." ./scripts/check_hygiene.py

run_tests_in() {
  local dir="${1%/}"
  [[ -f "$dir/pubspec.yaml" && -d "$dir/test" ]] || return 0

  if grep -qE '^[[:space:]]*sdk:[[:space:]]*flutter([[:space:]]|$)' "$dir/pubspec.yaml"; then
    run_step "Running flutter test in $dir..." bash -c "cd \"$dir\" && flutter test --reporter=failures-only"
  else
    run_step "Running dart test in $dir..." bash -c "cd \"$dir\" && dart test --reporter=failures-only"
  fi
}

if [[ "${#TARGETS[@]}" -gt 0 ]]; then
  for pkg_dir in "${TARGETS[@]}"; do
    run_tests_in "$pkg_dir"
  done
else
  for pkg_dir in packages/* apps/*; do
    [[ -d "$pkg_dir" ]] || continue
    run_tests_in "$pkg_dir"
  done
fi

if [[ "$QUIET" -eq 1 ]]; then
  echo "CHECK_OK: format, analyze, hygiene, and tests passed."
else
  echo "==> All deterministic checks passed!"
fi
