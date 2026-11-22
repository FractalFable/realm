#!/usr/bin/env bash
set -uo pipefail

# Claude Code PostToolUse hook (.claude/settings.json): silently auto-format edited/written .dart files.
# Fast-exits in pure bash without spawning python3 when no .dart path is in the payload.

payload="$(cat 2>/dev/null || true)"

if [[ "$payload" != *".dart"* ]]; then
  exit 0
fi

target_file="$(
  python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)
path = (data.get("tool_input") or {}).get("file_path")
if isinstance(path, str) and path.endswith(".dart"):
    print(path)
' <<< "$payload" 2>/dev/null || true
)"

if [[ -n "$target_file" && -f "$target_file" ]] && command -v dart >/dev/null 2>&1; then
  dart format "$target_file" >/dev/null 2>&1 || true
fi

exit 0
