# Prompt: move a project to the shared AI config folder (`~/.ai-shared`)

Paste everything below the line into Claude Code, inside the project's
devcontainer, in a project generated before the kit's `~/.ai-shared` folder
existed.

<!--
WHY THIS EXISTS (comments are for people; Claude may ignore them)

The kit used to share only a personal CLAUDE.md, from the host folder
~/.claude-devcontainers/shared, mounted at ~/.claude-shared and linked by
.devcontainer/link-shared-claude-rules.sh. It now shares rules (AGENTS.md),
skills, commands and agents for several AI tools, from ~/.ai-shared. The old
name said "claude" and "devcontainers" for content that is neither.

Old projects keep working without this migration: script/install-shared leaves
~/.claude-devcontainers/shared as a symlink to ~/.ai-shared. They only miss
things: the old link script links CLAUDE.md alone, and CLAUDE.md imports
AGENTS.md, which is not found unless AGENTS.md is linked beside it. Skills,
commands, agents and the Codex links are not linked at all. This prompt brings
a project's mount and link script up to date.

Design choices the prompt keeps:
  - It copies the kit's own template for the link script instead of rewriting
    it, so every project gets the same file. The kit is the source of truth.
  - initializeCommand only creates the (empty) host folder; the kit's
    script/install-shared fills it. The container cannot reach the kit's
    scripts on the host, so the host step is printed for the owner to run.
  - It never touches ~/.claude-devcontainers/<project> (Claude's own sign-in
    and history), which keeps its name.
-->

---

Update this project's devcontainer to the kit's shared AI config folder. Work in
these steps, and stop to ask me before anything destructive.

1. **Find out how it is set up today.** Read `.devcontainer/devcontainer.json`
   and list `.devcontainer/`. Report which case applies:
   - Mount `.claude-devcontainers/shared` at `.claude-shared` and a
     `link-shared-claude-rules.sh` step: the old setup. Continue.
   - Mount `.ai-shared` and `link-shared-ai-config.sh`: already migrated. Tell
     me and stop.
   - No shared mount at all: tell me and stop; this project predates the shared
     folder and needs a different change.
   Note any other mounts, `initializeCommand` and `postCreateCommand` entries to
   keep.

2. **Get the kit's current files.** Use the kit's `templates/link-shared-ai-config.sh`
   (see the kit's `HANDOFF.md`, "Access the kit from the project devcontainer",
   if the kit is not mounted). Do not write the script from memory.

3. **Edit `.devcontainer/devcontainer.json`.**
   - Replace the mount `source=${localEnv:HOME}/.claude-devcontainers/shared,target=/home/vscode/.claude-shared,type=bind,readonly`
     with `source=${localEnv:HOME}/.ai-shared,target=/home/vscode/.ai-shared,type=bind,readonly`.
     Use the remote user's home if it is not `/home/vscode`.
   - Replace the `postCreateCommand` entry that runs
     `link-shared-claude-rules.sh` with one that runs
     `bash .devcontainer/link-shared-ai-config.sh`. Keep the other entries.
   - Make sure `initializeCommand` also runs `mkdir -p "${localEnv:HOME}/.ai-shared"`
     on the host. Keep whatever it already does. If the project's
     `create-host-claude-folders.sh` creates the shared folder or copies a
     starter file into it, replace it with the kit's current template.
   - Leave the per-project mount at `~/.claude` and `CLAUDE_CONFIG_DIR` alone.

4. **Replace the files.** Add `.devcontainer/link-shared-ai-config.sh` from the
   kit. Delete `.devcontainer/link-shared-claude-rules.sh` and
   `.devcontainer/shared-claude-rules-starter.md` if present, and say that you
   did. Update any README text that names the old paths.

5. **Give me the host command.** You cannot run the kit's installer from inside
   the container, so print this for me to run on the host, and wait for me to
   confirm. It is safe to repeat:
   `~/develop/devcontainer-kit/script/install-shared`
   It copies the kit's `shared/` folder into `~/.ai-shared` and keeps the old
   path working as a symlink for projects not yet migrated.

6. **Tell me how to finish:** run "Dev Containers: Rebuild Container". Then check
   inside the container and report each result:
   - `ls -l ~/.claude ~/.codex ~/.agents` shows links into `/home/vscode/.ai-shared`.
     A tool's folder may be absent if the shared folder has nothing for it.
   - `touch ~/.ai-shared/x` fails with "Read-only file system".
   - In a new Claude session, a rule from `~/.ai-shared/AGENTS.md` is quoted
     when I ask for it.
   Run `.devcontainer/check-dependencies.sh` as well. Do not commit unless I ask.
