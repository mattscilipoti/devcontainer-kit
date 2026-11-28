#!/usr/bin/env bash
# Runs in the container (postCreateCommand). Links the read-only shared rules and
# skills into each AI tool's config folder. Never replaces a real file or folder
# the user made there, and skips anything the shared folder does not have.
set -euo pipefail

shared_folder="${SHARED_FOLDER:-$HOME/.ai-shared}"
claude_folder="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

link_unless_real() {
  local source="$1" target="$2"
  [ -e "$source" ] || return 0
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Keeping existing $target; not linking the shared one."
    return
  fi
  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
}

# Claude Code. AGENTS.md is linked too because shared CLAUDE.md imports it.
for name in CLAUDE.md AGENTS.md skills commands agents; do
  link_unless_real "$shared_folder/$name" "$claude_folder/$name"
done

# Codex and other tools that follow the Agent Skills layout. Harmless if unused.
link_unless_real "$shared_folder/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_unless_real "$shared_folder/skills" "$HOME/.agents/skills"
