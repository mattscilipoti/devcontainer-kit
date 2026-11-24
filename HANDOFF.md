# Handoff: where devcontainer-kit stands

Status and migration guidance for devcontainer-kit. This document may be copied
into any project to help its AI assistant compare an existing devcontainer with
the kit. Follow that project's instructions and confirm its requirements with
the owner; do not assume a particular stack or project configuration.

## For the human: start a migration

Copy this file into the project you want to migrate. On the host, replace
`<project>` with that project's folder:

```bash
cp -i ~/develop/devcontainer-kit/HANDOFF.md "<project>/devcontainer-kit-migration-handoff.md"
```

In that project's AI session, ask it to read the copied file and follow
**Migrating an existing project** below. It will obtain the kit and propose a
plan; answer its questions and approve changes before it proceeds. After a
devcontainer change, rebuild when asked. The copied handoff is temporary unless
the project needs to keep it.

## Update: 2026-11-24

- The owner chose to leave this kit without its own devcontainer for now, so it
  keeps simple access to host folders. Revisit only if host dependencies become
  insufficient.
- `script/test-generation` checks every non-empty stack combination and the
  Rails browser-tests option with the default database, SQLite.
- A `rails,web --browser-tests` Dockerfile built; Rails, SQLite, Chromium and
  ChromeDriver ran, and a non-root user could write to `/usr/local/bundle`.
- A generated `go,rails,web --browser-tests --docker-in-docker` project opened
  in VS Code and rebuilt. The dependency check and post-create commands passed;
  Claude bind mounts, shared-rule link, bundle permissions, and Docker-in-Docker
  were checked. This combined test does not replace testing each stack alone.
- The standalone `go` stack also rebuilt in VS Code and passed its dependency
  and shared-rule checks. Its scratch project is at
  `~/develop/devcontainer-kit-vscode-go-validation/`.
- The standalone `ruby` stack rebuilt in VS Code and passed its dependency,
  shared-rule, and non-root bundle-directory permission checks. Its scratch
  project is at `~/develop/devcontainer-kit-vscode-ruby-validation/`.
- The standalone `rails` stack rebuilt in VS Code with default SQLite and
  passed its dependency, shared-rule, and non-root bundle-directory permission
  checks. Its scratch project is at
  `~/develop/devcontainer-kit-vscode-rails-validation/`.
- The standalone `web` stack rebuilt in VS Code and passed its dependency and
  shared-rule checks. Its scratch project is at
  `~/develop/devcontainer-kit-vscode-web-validation/`.
- The opt-in `web --lighthouse` stack rebuilt and passed its dependency checks
  and a Lighthouse audit of a trusted local page using an explicit
  `--headless --no-sandbox` flag. Docker's default seccomp profile is retained.
  The opt-in also generates a quarterly sandbox review reminder. Two live
  workflow runs in the public test repository created one review issue and
  then detected it without creating a duplicate. The test issue was closed and
  the temporary reminder workflow removed.
- Generation preserved unrelated scratch-project files and existing `AGENTS.md`
  content, and refused to overwrite generated files without `--force`.
- Docker Desktop could not mount the scratch workspace under `/tmp`; a scratch
  project under `~/develop/` worked. The VS Code validation project remains at
  `~/develop/devcontainer-kit-vscode-validation/` with its container running.
- A live workflow run in `mattscilipoti/devcontainer-kit-workflow-test-`
  passed the current-version job, but the scan job could not start because
  Trivy action `v0.28.0` depended on a deleted setup-action tag. Updated the
  template to the latest Trivy action, `v0.36.0`, and added `pipefail` so
  outdated-version failures are not hidden by `tee`. A second run completed
  both Trivy scans, but GitHub rejected their combined SARIF upload because
  the reports had the same category. The template now uploads each separately
  and limits SARIF severity; a third run passed both scans and uploads.
  Two further runs with an intentionally outdated Node pin created and then
  commented on the same version-drift issue; the original pin was restored.
  The owner closed the test issue. A subsequent run passed with all direct
  workflow action references pinned to full commit SHAs in response to a
  security alert, which the owner confirmed was resolved. The public test
  repository has an active weekly workflow. Ask before pushing or changing
  repository settings.

## Starting here

- In the kit repository, read [AGENTS.md](AGENTS.md), [README.md](README.md),
  and [PROMPT.md](PROMPT.md). The kit has no devcontainer of its own.
- In a project receiving this handoff, read that project's instructions first,
  then follow the migration section below. Access the kit using the instructions
  there if it is not already available.

## Goal

A system an AI (possibly not yet inside a devcontainer, with access only to
`~/develop` and `~/.claude*`) can follow to create a devcontainer for a new
project: ask what the project is, scaffold it with the **latest releases**,
set up **Claude auth and history that survive rebuilds**, verify it, and
schedule out-of-date and security checks. Favor automation over manual steps.

## What the owner decided

- Personal use only: no publishing templates to a registry.
- Prefer industry-standard parts (official images, Dev Container Features,
  Dependabot) over homegrown ones, because maintainers keep them current.
- Stacks are **composable** (for example `go,ruby` or `rails,web`) and the AI
  asks what the project is first. Do not assume Ruby or Rails. First stacks:
  Go, Ruby, Ruby on Rails, HTML/CSS/JS (`web`).
- Node defaults to **LTS**; Rails defaults to **SQLite** (Postgres is a question).
- Dependencies go in the devcontainer, not the workspace. After a dependency
  change the AI informs the user, waits for the rebuild, then runs
  `check-dependencies.sh`.
- Scheduled checks: Dependabot plus a weekly workflow (version drift issue and a
  Trivy scan). No AI usage on a schedule.
- Projects are on GitHub.

## Claude auth and history (the problem this solves)

A devcontainer's own filesystem is deleted on every rebuild. A Docker named volume
survives rebuilds but was lost anyway: its name used `${devcontainerId}` (changes
with the folder path), and prunes delete unused volumes. Solution, already in the
templates: bind-mount a **host folder outside the repo**,
`~/.claude-devcontainers/<project>/` at `~/.claude` (it holds `.credentials.json`),
with `CLAUDE_CONFIG_DIR` set, and a read-only shared folder
`~/.claude-devcontainers/shared/` linked in for personal `CLAUDE.md` rules.
`initializeCommand` creates the folders on the host first (a bind mount fails when
the source is missing). `prompts/move-claude-config-to-host-bind-mount.md`
converts older projects.

## What exists

`README.md` (humans), `PROMPT.md` (the AI's steps), `stacks/*.json`,
`templates/`, `script/new-devcontainer`, `script/latest-versions`, `prompts/`.

## Validation status

See the update above for stack, generator, and GitHub workflow validation.
These checks do not replace testing the receiving project's own requirements.
The Postgres option has not been validated in a rebuilt devcontainer.

## Open decisions

1. ~~Debian or Ubuntu base.~~ **Settled 2026-11-24:** Debian everywhere. Ruby uses
   the official `ruby:<version>-slim-<codename>` image (the `rubylang/ruby` images
   are Ubuntu-only, and Ubuntu's `chromium` is a snap stub that fails in
   containers); other stacks use `debian:stable-slim`. The codename comes from
   `script/latest-versions`. Ubuntu is not supported unless the owner asks.
2. ~~Dogfooding.~~ Leave the kit without its own devcontainer for now.
3. ~~Add a test.~~ Added `script/test-generation`.

## Next steps

1. For a receiving project, compare its existing configuration with the kit as
   described below, and get the owner's approval before making migration changes.
2. Commit and push changes only with the owner's approval.

## Migrating an existing project (do not run the generator over it)

### Access the kit from the project devcontainer

If the project container cannot see the host's kit folder, clone the pushed kit
into a temporary directory **inside the container**. This gives the session the
scripts, stacks, and templates without mounting the host workspace or Claude
credentials. GitHub access and `git`, `python3`, and network access are needed.
Only pushed commits are available; confirm the clone's commit with the owner if
the host kit may have unpushed changes.

```bash
set -e
kit_root="$(mktemp -d /tmp/devcontainer-kit-migration.XXXXXX)"
git clone https://github.com/mattscilipoti/devcontainer-kit.git "$kit_root/kit"
git -C "$kit_root/kit" remote set-url --push origin no-push://read-only-reference
git -C "$kit_root/kit" rev-parse HEAD
printf 'Kit and reference scratch directory: %s\n' "$kit_root"
```

The invalid push URL prevents an accidental `git push` from this clone; it is a
reminder, not a security boundary. HTTPS may still require existing GitHub
authentication for a private repository; do not put credentials in the URL.

Keep the printed path for the session; shell variables may not persist between
tool calls. Read `AGENTS.md` and `README.md` in the clone, and use this copied
handoff's migration instructions if they are newer than the clone. Use the
clone's `script/new-devcontainer` and its `stacks/` and `templates/` for the
comparison below. Generate the reference into a new directory under the printed
scratch path, **not** into the existing project.

If HTTPS authentication or network access fails, stop and ask the owner to copy
the tracked kit files into a new scratch folder in the project workspace from
the host. For example, on the host (replace `<project>` with the actual host
path, and do not run this if the destination already exists):

```bash
set -euo pipefail
mkdir "<project>/.kit-migration-reference"
git -C ~/develop/devcontainer-kit archive HEAD |
  tar -x -C "<project>/.kit-migration-reference"
git -C ~/develop/devcontainer-kit rev-parse HEAD
```

This copies the host kit's committed files without its `.git` directory or
untracked files. The session can use `.kit-migration-reference` as the kit
directory and a separate scratch directory for the generated reference; neither
belongs in the project's commits. Remove the scratch folders when finished.
Do not copy or mount SSH keys, tokens, or host Claude credentials. If the session
cannot access `/tmp`, agree on a scratch location it can access. A host bind
mount would require a devcontainer change and rebuild, so prefer the temporary
clone or an owner-provided copy.

### Compare and migrate

1. Inspect the project's instructions and existing devcontainer, dependencies,
   tests, CI, and scheduled checks. Ask the owner to confirm the project's stack,
   database, runtime version constraints, browser tests, and Docker needs.
   Preserve existing work and do not assume Rails, Node, or a particular database.
2. Generate a reference in a new scratch directory, never over the project.
   Before showing or running a command, replace every placeholder with the
   confirmed project's actual values. Include only the optional flags that apply;
   see the cloned kit's `README.md` for supported options and defaults:

   ```bash
   "<kit-dir>/script/new-devcontainer" \
     --project-dir "<scratch-reference-dir>" \
     --stacks "<confirmed-stacks>" --name "<project-name>"
   ```

3. Compare the reference with the project. Identify project-specific tools,
   mounts, ports, startup commands, tests, and CI settings to preserve. Discuss
   runtime upgrades, compatibility constraints, and proposed replacements with
   the owner before changing anything.
4. After approval, make the agreed changes without overwriting unrelated project
   files. Preserve existing project-specific checks and CI, and merge applicable
   kit changes rather than replacing configuration blindly.
5. After a dependency or devcontainer change, tell the owner to rebuild and
   **wait**. Once rebuilt, run the project's `check-dependencies.sh` inside the
   container, then the agreed project tests. Fix failures in configuration and
   repeat the rebuild-and-check cycle. Ask before pushing or changing GitHub
   settings.
