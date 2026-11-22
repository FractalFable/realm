#!/usr/bin/env python3
"""Deterministic repository hygiene checks (0 LLM tokens)."""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
MODEL_ID_RE = re.compile(
    r"\b(gemini-\d[\w.-]*|claude-(?:sonnet|opus|haiku)-[\w.-]+)\b",
    re.IGNORECASE,
)
WORKSPACE_RES_RE = re.compile(r"^\s*resolution:\s*workspace\s*$", re.MULTILINE)
LEGACY_GENUI_RE = re.compile(r"^\s*genui\s*:", re.MULTILINE)
URL_RE = re.compile(r"https?://", re.IGNORECASE)


def iter_markdown_files() -> list[pathlib.Path]:
    files: list[pathlib.Path] = []
    for name in ("README.md", "AGENTS.md", "CLAUDE.md"):
        p = ROOT / name
        if p.is_file():
            files.append(p)
    for folder in ("docs", ".claude"):
        d = ROOT / folder
        if d.is_dir():
            files.extend(
                p for p in sorted(d.rglob("*.md")) if "worktrees" not in p.parts
            )
    for pattern in ("packages/*/AGENTS.md", "apps/*/AGENTS.md", "packages/*/CLAUDE.md", "apps/*/CLAUDE.md"):
        files.extend(sorted(ROOT.glob(pattern)))
    return files


def strip_fenced_blocks(lines: list[str]) -> list[tuple[int, str]]:
    """Return (1-based line_no, text) excluding fenced code blocks."""
    out: list[tuple[int, str]] = []
    in_fence = False
    fence_char = ""
    for idx, line in enumerate(lines, start=1):
        stripped = line.lstrip()
        if not in_fence:
            if stripped.startswith("```") or stripped.startswith("~~~"):
                in_fence = True
                fence_char = stripped[:3]
                continue
            out.append((idx, line))
        else:
            if stripped.startswith(fence_char):
                in_fence = False
    return out


def strip_inline_code(line: str) -> str:
    return re.sub(r"`[^`]*`", "", line)


def check_markdown_files(errors: list[str]) -> None:
    model_routing_path = (ROOT / "docs" / "MODEL_ROUTING.md").resolve()
    for md in iter_markdown_files():
        rel = md.relative_to(ROOT)
        lines = md.read_text(encoding="utf-8").splitlines()
        for line_no, raw_line in strip_fenced_blocks(lines):
            clean_line = strip_inline_code(raw_line)
            for match in LINK_RE.finditer(clean_line):
                target = match.group(1).strip().split()[0]
                if target.startswith("<") and target.endswith(">"):
                    target = target[1:-1]
                if (
                    not target
                    or target.startswith("#")
                    or re.match(r"^(?:https?|mailto|file):", target, re.IGNORECASE)
                ):
                    continue
                path_part = target.split("#", 1)[0]
                if not path_part:
                    continue
                resolved = (md.parent / path_part).resolve()
                if not resolved.exists():
                    errors.append(
                        f"{rel}:{line_no}: broken relative link '{target}'"
                    )

            if md.resolve() != model_routing_path:
                for m in MODEL_ID_RE.finditer(raw_line):
                    errors.append(
                        f"{rel}:{line_no}: model ID '{m.group(1)}' must live only in docs/MODEL_ROUTING.md"
                    )


def check_pubspecs(errors: list[str]) -> None:
    for pattern in ("packages/*/pubspec.yaml", "apps/*/pubspec.yaml"):
        for pubspec in sorted(ROOT.glob(pattern)):
            rel = pubspec.relative_to(ROOT)
            text = pubspec.read_text(encoding="utf-8")
            if not WORKSPACE_RES_RE.search(text):
                errors.append(f"{rel}: missing 'resolution: workspace'")
            if LEGACY_GENUI_RE.search(text):
                errors.append(
                    f"{rel}: legacy 'genui:' dependency forbidden (use a2ui_core/a2ui_flutter)"
                )


def check_dart_lib_urls(errors: list[str]) -> None:
    for base in ("packages", "apps"):
        base_dir = ROOT / base
        if not base_dir.is_dir():
            continue
        for pkg in sorted(base_dir.iterdir()):
            lib_dir = pkg / "lib"
            if not lib_dir.is_dir():
                continue
            for dart_file in sorted(lib_dir.rglob("*.dart")):
                rel = dart_file.relative_to(ROOT)
                for line_no, line in enumerate(
                    dart_file.read_text(encoding="utf-8").splitlines(), start=1
                ):
                    stripped = line.lstrip()
                    if stripped.startswith("//") or "realm-allow-url" in line:
                        continue
                    if URL_RE.search(line):
                        errors.append(
                            f"{rel}:{line_no}: hardcoded http(s):// URL in lib/ (use ClientEndpointConfig or realm-allow-url)"
                        )


def main() -> int:
    errors: list[str] = []
    check_markdown_files(errors)
    check_pubspecs(errors)
    check_dart_lib_urls(errors)
    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        return 1
    print("Hygiene checks OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
