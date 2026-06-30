# Claude Code Instructions

Follow the project rules in `AGENTS.md`.

## Claude Code Integration

- Project subagents for Claude Code live in `.claude/agents/`.
- Project skills are maintained in `.agents/skills/` as the source of truth.
- Do not manually edit generated skill projections under `.claude/skills/`.
- When project skills change, regenerate IDE projections with:

```bash
scripts/sync-ide-skills.sh --target all --mode auto
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-ide-skills.ps1 -Target all -Mode auto
```
