#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
CHANGES_DIR = REPO_ROOT / "openspec" / "changes"

DESIGN_STAGES = [
    "brief",
    "explore",
    "propose",
    "design-review",
    "gate-design",
    "test-design",
    "write-handoff",
]

EXECUTION_STAGES = [
    "implement",
    "code-review",
    "gate-code",
    "test-write",
    "gate-test-code",
    "test-run",
    "gate-test",
    "archive",
    "requirement-sync",
]

ROLE_CONFIG = {
    "design": {
        "owner_ide": "cursor",
        "file_name": "design-state.json",
        "stages": DESIGN_STAGES,
        "skill_name": "feature-design",
    },
    "execution": {
        "owner_ide": "claude-code",
        "file_name": "execution-state.json",
        "stages": EXECUTION_STAGES,
        "skill_name": "feature-exec",
    },
}

STAGE_STATUSES = {"pending", "active", "completed", "failed", "skipped"}
GATE_RESULTS = {"passed", "failed", "skipped"}


def now_iso() -> str:
    return (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def change_dir(change_name: str) -> Path:
    return CHANGES_DIR / change_name


def orchestrator_dir(change_name: str) -> Path:
    return change_dir(change_name) / ".orchestrator"


def state_path(role: str, change_name: str) -> Path:
    return orchestrator_dir(change_name) / ROLE_CONFIG[role]["file_name"]


def handoff_path(change_name: str) -> Path:
    return orchestrator_dir(change_name) / "handoff.json"


def requirement_sync_path(change_name: str) -> Path:
    return orchestrator_dir(change_name) / "requirement-sync.json"


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    temp_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    temp_path.replace(path)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing file: {path}")
    except json.JSONDecodeError as exc:
        fail(f"invalid json in {path}: {exc}")


def print_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, indent=2))


def ensure_role(role: str) -> None:
    if role not in ROLE_CONFIG:
        fail(f"unsupported role: {role}")


def ensure_stage(role: str, stage: str) -> None:
    if stage not in ROLE_CONFIG[role]["stages"]:
        fail(f"unknown stage for role '{role}': {stage}")


def base_state(role: str, change_name: str, trust: bool) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "change_name": change_name,
        "role": role,
        "owner_ide": ROLE_CONFIG[role]["owner_ide"],
        "skill": ROLE_CONFIG[role]["skill_name"],
        "trust": trust,
        "status": "active",
        "current_stage": "",
        "stages": {stage: "pending" for stage in ROLE_CONFIG[role]["stages"]},
        "updated_at": now_iso(),
    }


def ensure_state(
    role: str,
    change_name: str,
    *,
    trust: bool = False,
    force: bool = False,
) -> dict[str, Any]:
    ensure_role(role)
    path = state_path(role, change_name)
    if path.exists() and not force:
        data = load_json(path)
        if trust and not data.get("trust"):
            data["trust"] = True
            data["updated_at"] = now_iso()
            atomic_write_json(path, data)
        return data
    data = base_state(role, change_name, trust)
    atomic_write_json(path, data)
    return data


def save_state(role: str, change_name: str, data: dict[str, Any]) -> None:
    data["updated_at"] = now_iso()
    atomic_write_json(state_path(role, change_name), data)
    if role == "execution":
        sync_handoff_from_execution(change_name, data)


def recompute_overall_status(data: dict[str, Any]) -> str:
    values = list(data["stages"].values())
    if any(value == "failed" for value in values):
        return "failed"
    if values and all(value in {"completed", "skipped"} for value in values):
        return "completed"
    if any(value == "active" for value in values):
        return "active"
    return data.get("status", "active")


def sync_handoff_from_execution(
    change_name: str, execution_state: dict[str, Any]
) -> None:
    path = handoff_path(change_name)
    if not path.exists():
        return

    handoff = load_json(path)
    target_status = (
        "completed"
        if execution_state.get("status") == "completed"
        else "execution_in_progress"
    )
    if handoff.get("status") != target_status:
        handoff["status"] = target_status
        handoff["updated_at"] = now_iso()
        atomic_write_json(path, handoff)


def init_state_command(args: argparse.Namespace) -> None:
    role = args.role
    data = ensure_state(role, args.change_name, trust=args.trust, force=args.force)
    if role == "execution":
        sync_handoff_from_execution(args.change_name, data)
    print_json(
        {
            "status": "ok",
            "role": role,
            "change_name": args.change_name,
            "path": str(state_path(role, args.change_name)),
        }
    )


def set_stage_command(args: argparse.Namespace) -> None:
    role = args.role
    ensure_role(role)
    ensure_stage(role, args.stage)
    if args.status not in STAGE_STATUSES:
        fail(f"invalid stage status: {args.status}")

    data = ensure_state(role, args.change_name, trust=args.trust)
    data["stages"][args.stage] = args.status

    if args.status == "active":
        data["current_stage"] = args.stage
    elif data.get("current_stage") == args.stage and args.status in {
        "completed",
        "failed",
        "skipped",
    }:
        next_pending = next(
            (name for name, status in data["stages"].items() if status == "pending"),
            "",
        )
        data["current_stage"] = next_pending

    if args.overall_status:
        data["status"] = args.overall_status
    else:
        data["status"] = recompute_overall_status(data)

    if args.trust:
        data["trust"] = True

    save_state(role, args.change_name, data)
    print_json(
        {
            "status": "ok",
            "role": role,
            "change_name": args.change_name,
            "stage": args.stage,
            "stage_status": args.status,
            "state_path": str(state_path(role, args.change_name)),
        }
    )


def set_gate_command(args: argparse.Namespace) -> None:
    role = args.role
    ensure_role(role)
    ensure_stage(role, args.gate)
    if args.result not in GATE_RESULTS:
        fail(f"invalid gate result: {args.result}")

    data = ensure_state(role, args.change_name, trust=args.trust)
    gate_history = data.setdefault("gate_decisions", [])
    gate_history = [item for item in gate_history if item.get("gate") != args.gate]
    record: dict[str, Any] = {
        "gate": args.gate,
        "result": args.result,
        "decided_at": now_iso(),
    }
    if args.reason:
        record["reason"] = args.reason
    gate_history.append(record)
    data["gate_decisions"] = gate_history

    data["stages"][args.gate] = (
        "completed"
        if args.result == "passed"
        else "skipped"
        if args.result == "skipped"
        else "failed"
    )
    data["status"] = recompute_overall_status(data)
    if data.get("current_stage") == args.gate and data["stages"][args.gate] != "active":
        next_pending = next(
            (name for name, status in data["stages"].items() if status == "pending"),
            "",
        )
        data["current_stage"] = next_pending
    save_state(role, args.change_name, data)

    if role == "design" and args.result == "failed":
        handoff_file = handoff_path(args.change_name)
        if handoff_file.exists():
            handoff = load_json(handoff_file)
            handoff["status"] = "needs_design_revision"
            handoff["updated_at"] = now_iso()
            atomic_write_json(handoff_file, handoff)

    print_json(
        {
            "status": "ok",
            "role": role,
            "change_name": args.change_name,
            "gate": args.gate,
            "result": args.result,
        }
    )


def write_handoff_command(args: argparse.Namespace) -> None:
    ensure_state("design", args.change_name, trust=args.trust)
    required_artifacts = args.required or [
        "proposal.md",
        "design.md",
        "tasks.md",
        "test-plan.md",
    ]
    optional_artifacts = args.optional or []

    payload = {
        "schema_version": 1,
        "change_name": args.change_name,
        "status": args.status,
        "design_gate_passed": args.design_gate_passed,
        "producer": {
            "ide": args.producer_ide,
            "skill": args.producer_skill,
            "updated_at": now_iso(),
        },
        "required_artifacts": required_artifacts,
        "optional_artifacts": optional_artifacts,
        "executor_notes": args.executor_note or [],
        "pending_risks": args.pending_risk or [],
        "gate_decisions": args.gate_decision or [],
    }
    atomic_write_json(handoff_path(args.change_name), payload)

    design_state = ensure_state("design", args.change_name, trust=args.trust)
    design_state["stages"]["write-handoff"] = "completed"
    design_state["current_stage"] = "write-handoff"
    design_state["status"] = (
        "completed" if args.status == "design_ready" else design_state.get("status", "active")
    )
    save_state("design", args.change_name, design_state)

    print_json(
        {
            "status": "ok",
            "change_name": args.change_name,
            "handoff_path": str(handoff_path(args.change_name)),
        }
    )


def validate_handoff_command(args: argparse.Namespace) -> None:
    handoff = load_json(handoff_path(args.change_name))
    errors: list[str] = []

    for field in ["schema_version", "change_name", "status", "design_gate_passed"]:
        if field not in handoff:
            errors.append(f"missing field: {field}")

    if handoff.get("status") != args.expect_status:
        errors.append(
            f"handoff status mismatch: expected '{args.expect_status}', got '{handoff.get('status')}'"
        )

    if handoff.get("design_gate_passed") is not True:
        errors.append("design_gate_passed must be true")

    if args.check_artifacts:
        root = change_dir(args.change_name)
        for relative_path in handoff.get("required_artifacts", []):
            if not (root / relative_path).exists():
                errors.append(f"missing required artifact: {relative_path}")

    if errors:
        for item in errors:
            print(item, file=sys.stderr)
        raise SystemExit(1)

    print_json(
        {
            "status": "ok",
            "change_name": args.change_name,
            "handoff_path": str(handoff_path(args.change_name)),
            "handoff_status": handoff.get("status"),
        }
    )


def set_requirement_sync_command(args: argparse.Namespace) -> None:
    payload = {
        "schema_version": 1,
        "change_name": args.change_name,
        "status": args.status,
        "requirement_id": args.requirement_id,
        "title": args.title,
        "week_id": args.week_id,
        "pipeline_id": args.pipeline_id,
        "action": args.action,
        "updated_at": now_iso(),
    }
    if args.summary:
        payload["summary"] = args.summary
    atomic_write_json(requirement_sync_path(args.change_name), payload)
    print_json(
        {
            "status": "ok",
            "change_name": args.change_name,
            "requirement_sync_path": str(requirement_sync_path(args.change_name)),
        }
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Shared orchestrator state helper for Cursor and Claude Code."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_design = subparsers.add_parser("init-design")
    init_design.add_argument("change_name")
    init_design.add_argument("--trust", action="store_true")
    init_design.add_argument("--force", action="store_true")
    init_design.set_defaults(role="design", handler=init_state_command)

    init_execution = subparsers.add_parser("init-execution")
    init_execution.add_argument("change_name")
    init_execution.add_argument("--trust", action="store_true")
    init_execution.add_argument("--force", action="store_true")
    init_execution.set_defaults(role="execution", handler=init_state_command)

    set_stage = subparsers.add_parser("set-stage")
    set_stage.add_argument("role", choices=sorted(ROLE_CONFIG.keys()))
    set_stage.add_argument("change_name")
    set_stage.add_argument("stage")
    set_stage.add_argument("status", choices=sorted(STAGE_STATUSES))
    set_stage.add_argument(
        "--overall-status",
        choices=["active", "completed", "failed", "paused", "skipped"],
    )
    set_stage.add_argument("--trust", action="store_true")
    set_stage.set_defaults(handler=set_stage_command)

    set_gate = subparsers.add_parser("set-gate")
    set_gate.add_argument("role", choices=sorted(ROLE_CONFIG.keys()))
    set_gate.add_argument("change_name")
    set_gate.add_argument("gate")
    set_gate.add_argument("result", choices=sorted(GATE_RESULTS))
    set_gate.add_argument("--reason")
    set_gate.add_argument("--trust", action="store_true")
    set_gate.set_defaults(handler=set_gate_command)

    write_handoff = subparsers.add_parser("write-handoff")
    write_handoff.add_argument("change_name")
    write_handoff.add_argument("--status", default="design_ready")
    write_handoff.add_argument(
        "--design-gate-passed",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    write_handoff.add_argument(
        "--producer-ide",
        default=ROLE_CONFIG["design"]["owner_ide"],
    )
    write_handoff.add_argument(
        "--producer-skill",
        default=ROLE_CONFIG["design"]["skill_name"],
    )
    write_handoff.add_argument("--required", action="append")
    write_handoff.add_argument("--optional", action="append")
    write_handoff.add_argument("--executor-note", action="append")
    write_handoff.add_argument("--pending-risk", action="append")
    write_handoff.add_argument("--gate-decision", action="append")
    write_handoff.add_argument("--trust", action="store_true")
    write_handoff.set_defaults(handler=write_handoff_command)

    validate_handoff = subparsers.add_parser("validate-handoff")
    validate_handoff.add_argument("change_name")
    validate_handoff.add_argument("--expect-status", default="design_ready")
    validate_handoff.add_argument("--check-artifacts", action="store_true")
    validate_handoff.set_defaults(handler=validate_handoff_command)

    requirement_sync = subparsers.add_parser("set-requirement-sync")
    requirement_sync.add_argument("change_name")
    requirement_sync.add_argument("--requirement-id", required=True)
    requirement_sync.add_argument("--title", required=True)
    requirement_sync.add_argument("--week-id", required=True)
    requirement_sync.add_argument("--action", required=True, choices=["created", "updated"])
    requirement_sync.add_argument("--status", default="synced")
    requirement_sync.add_argument("--pipeline-id")
    requirement_sync.add_argument("--summary")
    requirement_sync.set_defaults(handler=set_requirement_sync_command)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.handler(args)


if __name__ == "__main__":
    main()
