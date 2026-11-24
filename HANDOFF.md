# Handoff: where devcontainer-kit stands

Written 2026-11-24 from a planning and build session in the `on_board_with_matt`
project, so the work can continue here, in this repo
(`git@github.com:mattscilipoti/devcontainer-kit.git`, at
`~/develop/devcontainer-kit/`). Delete or replace this file once the open
decisions below are settled.

## Starting here

This file was written inside the `on_board_with_matt` devcontainer, where the kit
lived as an untracked staging folder. To continue:

1. On the host, copy it into place and push (nothing has been pushed):
   `cp -a <on_board_with_matt>/devcontainer-kit ~/develop/devcontainer-kit`, then
   `git init`, commit, `git remote add origin git@github.com:mattscilipoti/devcontainer-kit.git`,
   `git push -u origin main`. Ask the owner before pushing.
2. Open `~/develop/devcontainer-kit` in your tool. The kit needs only `python3`,
   `curl`, `git`, and `docker` (to test builds); it has no devcontainer of its own.
3. Read [AGENTS.md](AGENTS.md), then the sections below. Settle the open decisions,
   then do the next steps in order.

The `on_board_with_matt` repo tracks this work as an **In progress** feature in its
`docs/features.md` ("Devcontainer kit for new projects"). When the kit is done
(generates and verifies every stack), the owner records its actuals there; do not
edit that repo from here without being asked.

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
the source is missing). The first project to adopt this is `on_board_with_matt`
(commit `99b41d6` there). `prompts/move-claude-config-to-host-bind-mount.md`
converts older projects.

## What exists

`README.md` (humans), `PROMPT.md` (the AI's steps), `stacks/*.json`,
`templates/`, `script/new-devcontainer`, `script/latest-versions`, `prompts/`.

## Tested and not tested

State as of the end of the 2026-11-24 session (Debian switch included).

**Tested:**
- Every stack alone, plus `go,ruby` and `rails,web --database postgres
  --browser-tests`, generate valid `devcontainer.json`, shell scripts, and
  Dockerfiles. Unknown stacks and existing files give clear errors.
- The generated **Go** Dockerfile (`debian:stable-slim`) builds.
- `script/latest-versions` resolves Ruby 4.0.10 (`ruby:4.0.10-slim-trixie`), Go
  1.27.4, Node LTS 26, Rails 8.1.4.1, Debian `trixie`.
- `check-versions.sh` exits 0 when current and 1 when behind.
- Before the Debian switch, a generated Rails image on the Ubuntu-based
  `rubylang` image built and ran (gem folder writable by a non-root user). That
  image is gone; the Debian equivalent has **not** been confirmed.

**Not tested (do these first):**
- A build of the generated `rails,web --database postgres --browser-tests`
  Dockerfile on `ruby:4.0.10-slim-trixie`. It was started but the result was not
  seen. Check that `chromium`, `chromium-driver`, `libvips-dev`, `libpq-dev` install,
  `rails --version` works, and a non-root user can write to `/usr/local/bundle`.
- Opening a generated project in VS Code: the `common-utils` Feature creating the
  `vscode` user on a Debian base, the bind mounts, `postCreateCommand`, and the
  Go, Node, and docker-in-docker Features.
- The GitHub workflow (the `aquasecurity/trivy-action@0.28.0` version was chosen
  from memory; `scheduled-checks.yml` has never run).
- That `script/new-devcontainer` leaves an existing project's other files alone.

## Open decisions

1. ~~Debian or Ubuntu base.~~ **Settled 2026-11-24:** Debian everywhere. Ruby uses
   the official `ruby:<version>-slim-<codename>` image (the `rubylang/ruby` images
   are Ubuntu-only, and Ubuntu's `chromium` is a snap stub that fails in
   containers); other stacks use `debian:stable-slim`. The codename comes from
   `script/latest-versions`. Ubuntu is not supported unless the owner asks.
2. **Dogfooding.** The kit has no devcontainer of its own and no `python` stack.
   Add a small `python` stack and generate the kit's own devcontainer, or leave it.
3. **Add a test.** A script that generates every stack combination into a scratch
   folder and checks the JSON and shell syntax would catch regressions cheaply.

## Next steps

1. Settle decisions 2 and 3.
2. Work through the untested list: build, then open each stack in VS Code, rebuild,
   run `.devcontainer/check-dependencies.sh`, and fix what breaks.
3. Migrate `on_board_with_matt` (plan below).
4. Commit and push this repo. The owner pushes, or asks first.

## Migrating on_board_with_matt (do not run the generator over it)

It predates the kit: Debian `stable-slim` with Debian's Ruby, Node 24 (the runtime
Neon Functions use, so keep `--node 24`), the Neon CLI, Lighthouse, a Real-ESRGAN
upscaler virtualenv, Chromium, Postgres client and docker-in-docker.
1. Generate a reference copy in `/tmp`:
   `script/new-devcontainer --project-dir /tmp/obwm --stacks rails,web --database postgres --browser-tests --node 24 --name on_board_with_matt`.
2. Move to the kit's Ruby base, `ruby:<version>-slim-trixie` (Ruby 3.3 to 4.0 is a real upgrade: run the tests
   and `bin/bundler-audit`, and update `.ruby-version`), or pin 3.3/3.4.
3. Keep project-specific parts: Neon CLI and Lighthouse, upscaler venv and its
   weights check, `python3-venv`, locales, the `neon` volume mount, `npm ci
   --prefix functions/intake`, `git config core.hooksPath .githooks`,
   `portsAttributes`, docker-in-docker, and its own `check-dependencies.sh`.
4. Let the kit replace: the manual Node tarball (Node Feature at 24), `useradd` and
   sudo (`common-utils`), the host and link scripts, `versions.json`,
   `check-versions.sh`, `scheduled-checks.yml`.
5. Add the `devcontainers` ecosystem to the project's `dependabot.yml`; keep its
   `ci.yml`. Rebuild, run `check-dependencies.sh`, `bin/rails test`, and
   `script/lighthouse`.
Do the migration as its own small feature, after the print-board feature is
committed (it now is).
