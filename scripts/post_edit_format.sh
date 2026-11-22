#!/usr/bin/env bash
set -uo pipefail

# Antigravity PostToolUse hook: silently auto-format edited/written .dart files.
# Fast-exits in pure bash without spawning python3 when no .dart file is in payload.

payload="$(cat 2>/dev/null || true)"

if [[ "$payload" != *".dart"* ]]; then
  printf '{}\n'
  exit 0
fi

target_file="$(
  python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)
if data.get("error"):
    sys.exit(0)
args = (data.get("toolCall") or {}).get("args") or {}
for key in ("Path", "TargetFile", "path"):
    val = args.get(key)
    if isinstance(val, str) and val.endswith(".dart"):
        print(val)
        break
' <<< "$payload" 2>/dev/null || true
)"

if [[ -n "$target_file" && -f "$target_file" ]]; then
  dart format "$target_file" >/dev/null 2>&1 || true
fi

printf '{}\n'
exit 0
