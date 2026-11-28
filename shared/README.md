# shared/: personal AI rules, skills, commands, agents

Installed to `~/.ai-shared/` on the host by
`script/install-shared`, mounted read-only in every devcontainer, and linked into
each tool's config folder by `link-shared-ai-config.sh`.

| Path | What | Tools that read it |
|---|---|---|
| `AGENTS.md` | tool-neutral rules | Claude (via `CLAUDE.md`), Codex |
| `CLAUDE.md` | imports `AGENTS.md`; add Claude-only rules here | Claude Code |
| `skills/<name>/SKILL.md` | Agent Skills open-standard skills | Claude Code, Codex, Cursor, others |
| `commands/`, `agents/` | slash commands and subagents | Claude Code only (not portable) |

Add a skill: create `skills/<name>/SKILL.md` with `name` and `description`
frontmatter, run `script/install-shared`, then rebuild or re-run the link script.
