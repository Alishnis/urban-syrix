#!/usr/bin/env python3
"""Stage the backend as a Hugging Face Space (SDK: docker) in a clean folder.

Usage: python3 scripts/stage_hf_space.py [OUT_DIR]   (default: ./build/hf_space)

Layout produced (the Space's build context is its repo root, which is exactly
what backend/Dockerfile expects: `COPY backend/...` and `COPY modules/ /modules/`):

    README.md    Space front matter (sdk: docker, app_port: 8002)
    Dockerfile   copy of backend/Dockerfile
    backend/     git-tracked backend files (no tests, venvs, caches, tmp)
    modules/     git-tracked YOLO weights

Only git-tracked files are copied, so .env files and local junk never leak.
No secrets are read or written; configure them as Space secrets instead.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = ("backend/tests/",)
EXCLUDE_FILES = {
    "backend/pytest.ini",
    "backend/ruff.toml",
    "backend/requirements-test.txt",
    "backend/.env",
}

README = """---
title: Urban Syrix API
emoji: 🏙️
colorFrom: indigo
colorTo: green
sdk: docker
app_port: 8002
pinned: false
short_description: FastAPI backend for Urban Syrix (YOLOv8 incident detection, safe routing)
---

# Urban Syrix API

FastAPI backend (YOLOv8 fire / accident detection, safe routing, AI scoring
proxy) for [Urban Syrix](https://github.com/Alishnis/urban-syrix). This Space
is deployed automatically from GitHub; edit the code there, not here.

Health check: `/api/health`. Interactive docs: `/docs`.
"""


def tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z", "backend", "modules"],
        cwd=REPO,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return [f for f in out.split("\0") if f]


def main() -> int:
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else REPO / "build" / "hf_space")
    out_dir = out_dir.resolve()
    if out_dir == REPO or out_dir in REPO.parents or out_dir == Path(out_dir.anchor):
        print(f"error: refusing to wipe {out_dir}", file=sys.stderr)
        return 1
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    copied = 0
    for rel in tracked_files():
        if rel in EXCLUDE_FILES or rel.startswith(EXCLUDE_PREFIXES):
            continue
        src = REPO / rel
        if not src.is_file():
            continue
        dst = out_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        copied += 1

    shutil.copy2(REPO / "backend" / "Dockerfile", out_dir / "Dockerfile")
    (out_dir / "README.md").write_text(README, encoding="utf-8")

    for required in (
        "backend/requirements.txt",
        "backend/main.py",
        "backend/yolov8n.pt",
        "modules/fire-detection/fire_model.pt",
    ):
        if not (out_dir / required).exists():
            print(f"error: staged folder is missing {required}", file=sys.stderr)
            return 1

    print(f"Staged {copied} files + Dockerfile + README.md into {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
