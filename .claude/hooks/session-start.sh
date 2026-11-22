#!/usr/bin/env bash
# Claude Code SessionStart hook: installs the pinned Flutter SDK (and its Dart)
# in cloud sessions, then resolves workspace packages. Idempotent: a reused
# container skips both installs in well under a second.
#
# Also usable as the cloud environment's setup script (runs before Claude
# starts, so the Dart MCP server finds `dart` on the very first session):
#   CLAUDE_CODE_REMOTE=true bash .claude/hooks/session-start.sh
set -euo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
  exit 0
fi

ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT_DIR"

# Pin: keep in sync with .flutter-version (CI reads that file). Get the hash for
# a new version from releases_linux.json in the Flutter release bucket.
FLUTTER_VERSION="$(tr -d '[:space:]' < .flutter-version)"
FLUTTER_SHA256="4ad17fc8462fbcef2ba19ff4a78c0a16b7147fde1add8578e267ea62cdb92678"
FLUTTER_PINNED="3.50.1"
if [[ "$FLUTTER_VERSION" != "$FLUTTER_PINNED" ]]; then
  echo "session-start: .flutter-version ($FLUTTER_VERSION) != hook pin ($FLUTTER_PINNED); update FLUTTER_SHA256 in $0" >&2
  exit 1
fi

SDK_ROOT="${REALM_FLUTTER_HOME:-$HOME/.realm-sdk}"
FLUTTER_DIR="$SDK_ROOT/flutter-$FLUTTER_VERSION"
FLUTTER_BIN="$FLUTTER_DIR/bin"
log() { echo "session-start: $*" >&2; }

# 1. Flutter SDK (outside the repository; marker file lives inside the SDK dir).
if [[ ! -f "$FLUTTER_DIR/.realm-installed" ]]; then
  log "installing Flutter $FLUTTER_VERSION into $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$SDK_ROOT"
  tmp="$(mktemp -d "$SDK_ROOT/.download.XXXXXX")"
  trap 'rm -rf "$tmp"' EXIT
  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  curl -fsSL --retry 4 --retry-delay 2 -o "$tmp/flutter.tar.xz" "$url"
  echo "$FLUTTER_SHA256  $tmp/flutter.tar.xz" | sha256sum --check --status
  tar -xJf "$tmp/flutter.tar.xz" -C "$tmp"
  mv "$tmp/flutter" "$FLUTTER_DIR"
  rm -rf "$tmp"
  trap - EXIT
  # The SDK is a git checkout owned by another uid after extraction.
  git config --global --get-all safe.directory | grep -qxF "$FLUTTER_DIR" \
    || git config --global --add safe.directory "$FLUTTER_DIR"
  "$FLUTTER_BIN/flutter" --disable-analytics >/dev/null 2>&1 || true
  "$FLUTTER_BIN/dart" --disable-analytics >/dev/null 2>&1 || true
  "$FLUTTER_BIN/flutter" --version >/dev/null 2>&1
  touch "$FLUTTER_DIR/.realm-installed"
fi

# 2. Put flutter/dart on PATH for every process: symlinks cover MCP servers
#    (.mcp.json spawns `dart`), CLAUDE_ENV_FILE covers Bash tool calls.
if [[ -w /usr/local/bin ]]; then
  for tool in flutter dart; do
    if [[ "$(readlink /usr/local/bin/$tool 2>/dev/null || true)" != "$FLUTTER_BIN/$tool" ]]; then
      ln -sfn "$FLUTTER_BIN/$tool" "/usr/local/bin/$tool"
    fi
  done
fi
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "export PATH=\"$FLUTTER_BIN:\$HOME/.pub-cache/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
export PATH="$FLUTTER_BIN:$PATH"

# 3. Workspace packages: re-run `flutter pub get` only when a manifest, the
#    lockfile, the SDK pin or this script changed since the last success.
hashes=".dart_tool/.session-start.sha256"
if [[ ! -f .dart_tool/package_config.json ]] || ! sha256sum --check --status "$hashes" 2>/dev/null; then
  rm -f "$hashes"
  log "running flutter pub get"
  if ! out="$(flutter pub get 2>&1)"; then
    printf '%s\n' "$out" >&2
    exit 1
  fi
  mkdir -p .dart_tool
  sha256sum .claude/hooks/session-start.sh .flutter-version pubspec.yaml pubspec.lock \
    packages/*/pubspec.yaml $(ls apps/*/pubspec.yaml 2>/dev/null) > "$hashes" || rm -f "$hashes"
fi
