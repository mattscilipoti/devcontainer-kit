# Prompt: keep Claude Code sign-in and history in a host folder

Paste everything below the line into Claude Code, inside the project's
devcontainer, in the project you want to fix.

<!--
WHY THIS EXISTS (comments are for people; Claude may ignore them)

Claude Code runs inside the devcontainer and writes its sign-in, chat history,
and memory to ~/.claude. Only the workspace folder is shared with the host, so
by default ~/.claude lives in the container's own filesystem and is deleted on
every rebuild. Symptom: you sign in again and old chats are gone.

The first fix is usually a named Docker volume. It survives rebuilds, but:
  - The volume name often includes ${devcontainerId}, a hash of the folder path
    and config path. Open the project from another path (worktree, renamed
    folder) and you silently get a new, empty volume; the old one is orphaned.
  - A volume lives inside Docker's VM. `docker system prune --volumes` or
    Docker Desktop's "Clean up" removes volumes no container is using, and a
    rebuild briefly leaves the old one unused.
  - Volumes are hard to see, back up, or copy between machines.

A bind mount of a plain host folder avoids all of that: rebuilds, prunes, and
a changed devcontainerId cannot touch it, and normal host backups include it.

Design choices the prompt keeps:
  - The folder is OUTSIDE the repository. It holds .credentials.json (a login
    token); inside the working tree one `git add -A` could commit it.
  - It is a dedicated per-project folder, not the host's own ~/.claude. The
    host's .claude.json and credential storage (macOS Keychain) would clash.
  - initializeCommand creates the folder on the host first, because a bind
    mount fails when the source folder is missing. initializeCommand runs on
    the HOST, so ${localEnv:HOME} is the host home, and the same step can
    write the README there, which the container cannot reach.
  - CLAUDE_CONFIG_DIR stays set so .claude.json (sign-in state) is kept in the
    same folder instead of in the container's home directory.
-->

---

Move this project's Claude Code state (sign-in, chat history, memory) to a bind
mount of a host folder, so devcontainer rebuilds, `docker volume prune`, and a
changed `devcontainerId` cannot lose it. Work in these steps, and stop to ask
me before anything destructive.

1. **Find out how it is stored today.** Read `.devcontainer/devcontainer.json`
   and the Dockerfile. Report which case applies:
   - A named volume mounted at `/home/vscode/.claude` (or the remote user's
     `~/.claude`), possibly named with `${devcontainerId}`.
   - Nothing mounted: state lives in the container and is lost on rebuild.
   - Already a bind mount: tell me and stop.
   Note any existing `initializeCommand` (it can be a string, an array, or an
   object) and any existing `CLAUDE_CONFIG_DIR`.

2. **Edit `.devcontainer/devcontainer.json`.** Name the host folder after this
   repository folder, for example `~/.claude-devcontainers/<repo-folder-name>`.
   - Add or merge an `initializeCommand` that creates the folder on the host
     (`mkdir -p "${localEnv:HOME}/.claude-devcontainers/<name>"`). Keep any
     command already there. On a Windows host use `${localEnv:USERPROFILE}`.
   - Replace the Claude volume mount (or add one) with
     `source=${localEnv:HOME}/.claude-devcontainers/<name>,target=<remote user home>/.claude,type=bind`.
     Leave unrelated mounts (for example other tools' config volumes) alone.
   - Make sure `containerEnv` sets `CLAUDE_CONFIG_DIR` to the same target path.
   - Keep any Dockerfile step that creates and `chown`s `~/.claude`; it is
     harmless and fixes ownership if the mount is ever absent.
   - Do not put the folder inside the repository. If I ask for that, warn that
     `.credentials.json` would sit in the working tree and add it to
     `.gitignore` first.

3. **Update the docs.** If the README or setup docs describe the Claude volume,
   rewrite that part: where the state lives now, that it holds credentials and
   must stay outside the repo, how to sign out (delete the host folder), and
   that the first rebuild needs one sign-in unless I seed the folder.

4. **Give me the host commands to move existing state.** You cannot reach my
   host folder from inside the container, so print these for me to run on the
   host, in this order, and wait for me to confirm:
   - Find the old volume: `docker volume ls | grep -i claude`. If several
     exist, help me pick by listing `projects/` in each, read-only:
     `docker run --rm -v <vol>:/v:ro alpine ls /v/projects`. The right one has
     a directory named after this project's path (for example
     `-workspaces-<repo-folder-name>`).
   - Copy it, with Claude idle so `.claude.json` is not half-written:
     `mkdir -p ~/.claude-devcontainers/<name>` then
     `docker run --rm -v <vol>:/v:ro -v ~/.claude-devcontainers/<name>:/out alpine cp -a /v/. /out/`
   - If there is no old volume, history from before is gone for good (it was in
     a deleted container). Say so plainly; do not promise recovery.

5. **Add a README for the host folder.** Save the README template I give you
   (`claude-config-README.md` from the kit's `templates/`)
   as `.devcontainer/claude-config-README.md`. If I did not attach it, write the
   same points: what the folder is, why it exists, that it holds credentials and
   must never be committed or shared, how to back it up, and how to reset it.
   Then extend `initializeCommand` to copy it into the host folder when missing:
   `[ -f "$d/README.md" ] || cp .devcontainer/claude-config-README.md "$d/README.md"`.
   `initializeCommand` runs on the host in the project folder, so this reaches
   the host folder, which the container cannot write to before it starts.

6. **Tell me how to finish:** run "Dev Containers: Rebuild Container", confirm
   I am still signed in and old chats appear, then remove the old volume with
   `docker volume rm <vol>` once I am sure. Do not cancel the rebuild midway,
   and do not run `docker volume rm` yourself. Do not commit unless I ask.
