## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills referenced by this project. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.

### Available skills
- frontend-design: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics. (file: C:/Users/TANG/.codex/skills/frontend-design/SKILL.md)
- go-react-codestyle: Go+React full-stack project coding standards including Go style guide, TypeScript/React style guide, API conventions, and testing specifications. Use when working on Go+React projects and needing code style guidance, API design conventions, or testing best practices. (file: C:/Users/TANG/.codex/skills/go-react-codestyle/SKILL.md)
- go-react-stack: Create a new Go+React full-stack project with DDD architecture and React best practices. Use when users request creating a new full-stack project or scaffolding a Go+React application. (file: C:/Users/TANG/.codex/skills/go-react-stack/SKILL.md)
- e2e-test-demo: End-to-end test demo skill for validating KSkillHub platform Skill creation, upload, parsing, and display features. Use when performing smoke tests or regression tests on KSkillHub. (file: C:/Users/TANG/.codex/skills/e2e-test-demo/SKILL.md)

### How to use skills
- Discovery: The list above is the skills available for this project (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) When `SKILL.md` references relative paths (e.g. `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.
  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.
