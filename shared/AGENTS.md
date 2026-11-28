# Personal rules for every project and every AI tool

<!-- Source of truth: devcontainer-kit/shared/. `script/install-shared` copies this
folder to ~/.ai-shared/ on the host; devcontainers mount it
read-only. Edit here in the kit, not in the copy. Project rules belong in the
project's own AGENTS.md. Keep this file tool-neutral: Claude Code, Codex and
others all read it. -->

- Ask before anything outward-facing (pushing, changing GitHub settings).
- Look up the latest version of a dependency; do not rely on memory.
- Prefer Debian slim over Ubuntu.
