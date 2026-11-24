# devcontainer-kit

Personal kit for giving a new project a devcontainer with the latest language
releases, Claude Code sign-in and history that survive rebuilds, and scheduled
out-of-date and security checks. An AI or a human runs it. Repo:
`git@github.com:mattscilipoti/devcontainer-kit.git`, kept at
`~/develop/devcontainer-kit/`.

## Start here

- **AI:** read [PROMPT.md](PROMPT.md) and follow it.
- **Human:** answer the questions in PROMPT.md yourself, then run
  `script/new-devcontainer` (below).

## Migrate an existing project

On the host, copy [HANDOFF.md](HANDOFF.md) into the project you want to migrate.
Replace `<project>` with that project's host folder:

```bash
cp -i ~/develop/devcontainer-kit/HANDOFF.md "<project>/devcontainer-kit-migration-handoff.md"
```

In that project's AI session, ask it to read the copied handoff and follow its
**Migrating an existing project** section. It will obtain the kit, inspect the
project, and propose a migration rather than overwrite existing files. Answer
its questions and approve the plan before changes; after changes, rebuild the
container when asked. The copied handoff is temporary unless the project needs
to keep it; do not commit it accidentally.

## Shared and project-specific files

| Lives in | What | Shared by |
|---|---|---|
| `~/develop/devcontainer-kit/` | this kit: stacks, templates, scripts, prompts | every project |
| `~/.claude-devcontainers/shared/` | personal Claude rules (`CLAUDE.md`), mounted read-only | every project |
| `~/.claude-devcontainers/<project>/` | that project's Claude sign-in and history (holds credentials) | one project |
| `<project>/.devcontainer/`, `.github/`, `AGENTS.md` | generated devcontainer, scheduled checks, rules for AI | one project (committed) |

Fixing the kit or `shared/` reaches every project. A project's files are its own
once generated; the kit does not overwrite them unless asked (`--force`).

## Stacks

Stacks are small JSON fragments in [stacks/](stacks/). They compose: ask for
several and the kit merges their apt packages, Dev Container Features, VS Code
extensions, ports, and setup steps into one devcontainer.

| Stack | What it adds |
|---|---|
| `go` | Go from the official `go` Feature |
| `ruby` | the official `ruby:<version>-slim-<debian>` image as the base (every other stack uses `debian:stable-slim`) |
| `rails` | needs `ruby`; Rails gem, SQLite and libvips; options for Postgres and browser tests |
| `web` | HTML/CSS/JS: Node (LTS by default), Prettier and ESLint, a static-server port; optional Lighthouse |

Combine them, for example `--stacks go,ruby` or `--stacks rails,web`. To add a
stack, add `stacks/<name>.json` (copy the nearest one) and a row above.

## Run it

```bash
script/new-devcontainer --project-dir ~/develop/myapp --stacks rails,web \
    [--name myapp] [--node lts|latest|24] [--database sqlite|postgres] \
    [--browser-tests] [--lighthouse] [--docker-in-docker] [--dry-run]
```

It looks up the latest releases (`script/latest-versions`: endoflife.date,
RubyGems, Docker Hub, and npm when Lighthouse is selected), then writes
`.devcontainer/`, `.github/dependabot.yml`, `.github/workflows/scheduled-checks.yml`,
and a devcontainer section in `AGENTS.md`. Needs only `python3` and network access.

For web apps, `--lighthouse` adds Chromium and installs a pinned Lighthouse
globally inside the container before post-create checks. It requires the `web`
stack and a Node version supported by the selected Lighthouse release. The
weekly version check reports when Lighthouse is outdated; projects own their
audit targets and thresholds.

Docker's default security settings can prevent Chromium's sandbox from starting.
Until a safer compatible setup is available, audit **trusted local pages only**
with `lighthouse <url> --chrome-flags="--headless --no-sandbox"`. This disables
Chromium's sandbox for that run; the browser can access the container's mounted
files, credentials, and network. With `--lighthouse`, a quarterly GitHub
Actions workflow opens a review issue if one is not already open, so the project
can revisit this workaround. It runs without AI after the workflow is pushed.

## Validate generation

Run `script/test-generation` to generate every non-empty stack combination in a
temporary folder and check generated JSON and shell syntax. It also checks
Rails browser-tests with Lighthouse and SQLite. The script looks up current
versions, so it needs network access.

## Why the choices

- **Debian slim, strongly preferred, for every stack.** It is smaller and steadier
  than Ubuntu, and its packages work in containers (Ubuntu's `chromium` is a snap
  stub that does not run in one, which breaks browser tests). Use Ubuntu only if a
  project requires it, and say why in a comment. `script/latest-versions` finds
  the current stable codename (now `trixie`).
- **Ruby from the official `ruby` image.** Docker's `ruby:<version>-slim-trixie`
  tracks Ruby releases within days and is on Debian. The Ruby team's own
  `rubylang/ruby` image is Ubuntu-only, and the Ruby Dev Container Feature builds
  Ruby from source. The slim image has no compiler, so the stack adds
  `build-essential`. It runs as root, so the `common-utils` Feature adds the
  `vscode` user, and gems install into a world-writable `/usr/local/bundle`.
- **Features, not several templates, for combining.** No official template
  composes several stacks. Dev Container Features are the standard composition
  mechanism, and Dependabot updates them.
- **Node LTS by default.** LTS releases get about 30 months of fixes; "Current"
  releases can end within a year, and native packages lag on brand-new majors.
- **Rails defaults to SQLite.** Postgres adds client libraries and Docker.
- **Claude state on the host.** A devcontainer's own filesystem is deleted on
  every rebuild, and Docker volumes can be lost to prunes or a changed
  `devcontainerId`. A bind mount of a plain host folder cannot. The folder is
  outside the repo because it holds credentials. See
  [prompts/move-claude-config-to-host-bind-mount.md](prompts/move-claude-config-to-host-bind-mount.md)
  to convert an older project.
- **Dependencies live in the devcontainer.** Tools are rebuilt reproducibly for
  every developer and every AI, not installed by hand in one workspace.

## Scheduled checks

No AI runs on a schedule. Each project gets:
- **Dependabot** (weekly): Dev Container Features and the lockfile, bundler, npm,
  Go modules, GitHub Actions, plus security updates.
- **`scheduled-checks.yml`** (weekly, GitHub Actions): `check-versions.sh` opens
  an issue when a pinned language version is behind, and Trivy scans the base
  image and repository for high and critical vulnerabilities (results in the
  Security tab).

Turn on Dependabot alerts and security updates for the repository (Settings →
Code security), or with `gh`: see PROMPT.md step 8.

## Layout

```
README.md  PROMPT.md
stacks/       one JSON fragment per stack
templates/    files copied into every project (Claude mount scripts, checks, workflow)
script/       new-devcontainer, latest-versions
prompts/      one-off prompts (convert an older project's Claude volume)
```
