#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import sys
import urllib.error
import urllib.request


def check_url(label: str, url: str, start_hint: str, timeout: float) -> list[str]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            status = getattr(response, "status", None) or response.getcode()
        if 200 <= status < 400:
            return [f"[OK] {label}: {url} -> {status}"]
        return [f"[FAIL] {label}: {url} -> {status}", f"       Start with: {start_hint}"]
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        return [f"[FAIL] {label}: {url} ({exc})", f"       Start with: {start_hint}"]


def check_command(label: str, command: str, install_hint: str) -> list[str]:
    if shutil.which(command):
        return [f"[OK] {label}: found `{command}`"]
    return [f"[FAIL] {label}: missing `{command}`", f"       Install or expose PATH: {install_hint}"]


def report(lines: list[str]) -> int:
    has_failures = any(line.startswith("[FAIL]") for line in lines)
    for line in lines:
        print(line)
    if has_failures:
        print("Environment check failed.", file=sys.stderr)
        return 1
    print("Environment check passed.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Check local test environment readiness.")
    parser.add_argument(
        "mode",
        choices=["backend", "frontend", "qa", "integration"],
        help="Environment profile to validate.",
    )
    parser.add_argument("--backend-url", default="http://127.0.0.1:8080/healthz")
    parser.add_argument("--frontend-url", default="http://localhost:3000/")
    parser.add_argument("--timeout", type=float, default=2.0)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    lines: list[str] = []

    if args.mode in {"backend", "qa"}:
        lines.extend(check_url("backend server", args.backend_url, "make dev-backend", args.timeout))

    if args.mode in {"frontend", "qa"}:
        lines.extend(check_url("frontend server", args.frontend_url, "make dev-frontend", args.timeout))

    if args.mode == "integration":
        lines.extend(check_command("Go toolchain", "go", "install Go 1.24+"))
        lines.extend(check_command("Node.js", "node", "install Node.js 22+"))

    return report(lines)


if __name__ == "__main__":
    raise SystemExit(main())
