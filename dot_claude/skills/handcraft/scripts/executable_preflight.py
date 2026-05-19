#!/usr/bin/env python3
"""Handcraft pre-flight detection.

Subcommands:
  bootstrap   Full scan of the current project + host. Writes state.json,
              prints the same JSON to stdout.
  recheck     Loads cached state.json, returns drift deltas as JSON.
              Exit 0 if all clear, exit 1 if drift, exit 2 if missing/corrupt.

The model consumes the JSON and renders the user-facing banner. This script
makes no UI decisions — it only reports facts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

# (kind, scope-glob, language hint)
LSP_CANDIDATES = [
    ("pyright", "**/*.py", "python"),
    ("mypy", "**/*.py", "python"),
    ("tsserver", "**/*.{ts,tsx,js,jsx}", "ts/js"),
    ("deno", "**/*.{ts,tsx,js,jsx}", "ts/js"),
    ("rust-analyzer", "**/*.rs", "rust"),
    ("gopls", "**/*.go", "go"),
]

FORMATTER_CANDIDATES = [
    ("ruff", "**/*.py"),
    ("black", "**/*.py"),
    ("prettier", "**/*.{ts,tsx,js,jsx,json,md,css}"),
    ("eslint", "**/*.{ts,tsx,js,jsx}"),
    ("rustfmt", "**/*.rs"),
    ("gofmt", "**/*.go"),
]

TEST_RUNNER_CANDIDATES = [
    ("pytest", "**/*.py"),
    ("jest", "**/*.{ts,tsx,js,jsx}"),
    ("vitest", "**/*.{ts,tsx,js,jsx}"),
    ("cargo", "**/*.rs"),   # cargo test
    ("go", "**/*.go"),      # go test
]

CONVENTION_FILES = [
    "CLAUDE.md",
    "AGENTS.md",
    ".cursorrules",
    ".aider.conf.yml",
    "GEMINI.md",
]

LINTER_CONFIG_FILES = [
    "ruff.toml",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.json",
    ".eslintrc.yml",
    ".prettierrc",
    ".prettierrc.json",
    "pyproject.toml",   # only count if it has [tool.*]
]


def state_dir(cwd: Path) -> Path:
    """Resolve the state directory. Never inside the project."""
    claude_projects = Path.home() / ".claude" / "projects"
    if claude_projects.is_dir():
        slug = str(cwd.resolve()).replace("/", "-")
        return claude_projects / slug / "handcraft"
    xdg = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")
    project_hash = hashlib.sha256(str(cwd.resolve()).encode()).hexdigest()[:12]
    return Path(xdg) / "handcraft" / project_hash


def state_file(cwd: Path) -> Path:
    return state_dir(cwd) / "state.json"


def detect_memory_backend(cwd: Path) -> dict:
    # Convention files in cwd are the most reliable signal.
    for name in CONVENTION_FILES:
        p = cwd / name
        if p.is_file():
            return {"kind": "convention_file", "path": str(p)}
    # No host-memory probing — that's the model's job (it knows its own harness).
    return {"kind": "sidecar_fallback", "path": str(state_dir(cwd) / "prefs.md")}


def detect_coding_guidelines(cwd: Path) -> list[dict]:
    out: list[dict] = []
    for name in CONVENTION_FILES:
        p = cwd / name
        if p.is_file():
            out.append({
                "kind": "convention",
                "path": str(p),
                "rule_count": sum(1 for line in p.read_text(errors="ignore").splitlines() if line.strip()),
                "mtime": datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc).isoformat(),
            })
    for name in LINTER_CONFIG_FILES:
        p = cwd / name
        if not p.is_file():
            continue
        if name == "pyproject.toml":
            text = p.read_text(errors="ignore")
            if "[tool." not in text:
                continue
        out.append({
            "kind": "linter_config",
            "path": str(p),
            "rule_count": 0,
            "mtime": datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc).isoformat(),
        })
    return out


def detect_lsps() -> list[dict]:
    return [
        {"kind": kind, "version": "", "scope": scope, "language": lang, "ok": True}
        for kind, scope, lang in LSP_CANDIDATES
        if shutil.which(kind)
    ]


def detect_formatters() -> list[dict]:
    return [
        {"kind": kind, "scope": scope, "ok": True}
        for kind, scope in FORMATTER_CANDIDATES
        if shutil.which(kind)
    ]


def detect_test_runners() -> list[dict]:
    return [
        {"kind": kind, "scope": scope, "ok": True}
        for kind, scope in TEST_RUNNER_CANDIDATES
        if shutil.which(kind)
    ]


def detect_docs_access() -> list[dict]:
    """Conservative — only reports what this script can verify.

    MCP servers can't be enumerated from here; the model knows its own MCP
    list and should augment this. Web fetch is assumed if the host exposes
    it (also model's job to confirm).
    """
    out: list[dict] = []
    # Hint at Claude Code presence — weak signal that MCPs may be configured.
    if (Path.home() / ".claude").is_dir():
        out.append({"kind": "host_hint", "name": "claude_code_dir_present", "ok": True})
    return out


def bootstrap(cwd: Path) -> dict:
    state = {
        "version": 1,
        "bootstrapped_at": datetime.now(tz=timezone.utc).isoformat(),
        "cwd": str(cwd.resolve()),
        "memory_backend": detect_memory_backend(cwd),
        "coding_guidelines": detect_coding_guidelines(cwd),
        "lsps": detect_lsps(),
        "docs_access": detect_docs_access(),
        "test_runners": detect_test_runners(),
        "formatters": detect_formatters(),
        "surface_map": {},
        "deferred_gaps": [],
    }
    out_path = state_file(cwd)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(state, indent=2))
    return state


def recheck(cwd: Path) -> tuple[dict, int]:
    sf = state_file(cwd)
    if not sf.is_file():
        return {"error": "state_missing", "path": str(sf)}, 2
    try:
        state = json.loads(sf.read_text())
    except json.JSONDecodeError as e:
        return {"error": "state_corrupt", "detail": str(e), "path": str(sf)}, 2

    deltas: list[dict] = []

    for entry in state.get("coding_guidelines", []):
        p = Path(entry["path"])
        if not p.is_file():
            deltas.append({"type": "missing", "kind": "guideline", "path": str(p)})
            continue
        current = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc).isoformat()
        if current != entry.get("mtime"):
            deltas.append({"type": "modified", "kind": "guideline", "path": str(p)})

    for bucket in ("lsps", "formatters", "test_runners"):
        for entry in state.get(bucket, []):
            if not shutil.which(entry["kind"]):
                deltas.append({"type": "missing", "kind": bucket[:-1], "name": entry["kind"]})

    # New tools that weren't present at bootstrap.
    recorded_tools = {
        bucket: {e["kind"] for e in state.get(bucket, [])}
        for bucket in ("lsps", "formatters", "test_runners")
    }
    for kind, scope, _ in LSP_CANDIDATES:
        if shutil.which(kind) and kind not in recorded_tools["lsps"]:
            deltas.append({"type": "new", "kind": "lsp", "name": kind})
    for kind, _ in FORMATTER_CANDIDATES:
        if shutil.which(kind) and kind not in recorded_tools["formatters"]:
            deltas.append({"type": "new", "kind": "formatter", "name": kind})
    for kind, _ in TEST_RUNNER_CANDIDATES:
        if shutil.which(kind) and kind not in recorded_tools["test_runners"]:
            deltas.append({"type": "new", "kind": "test_runner", "name": kind})

    bootstrapped_at = datetime.fromisoformat(state["bootstrapped_at"])
    age_days = (datetime.now(tz=timezone.utc) - bootstrapped_at).days

    report = {
        "all_clear": len(deltas) == 0,
        "age_days": age_days,
        "state_path": str(sf),
        "deltas": deltas,
    }
    return report, (0 if not deltas else 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("subcommand", choices=["bootstrap", "recheck"])
    parser.add_argument("--cwd", default=os.getcwd(), help="Project root (default: cwd)")
    args = parser.parse_args()

    cwd = Path(args.cwd)
    if args.subcommand == "bootstrap":
        print(json.dumps(bootstrap(cwd), indent=2))
        return 0
    report, code = recheck(cwd)
    print(json.dumps(report, indent=2))
    return code


if __name__ == "__main__":
    sys.exit(main())
