# Prompt: create a devcontainer for a project

For an AI (any model) that may not be inside a devcontainer yet. You can read and
write `~/develop` and `~/.claude*` on the host. Follow the steps in order.

<!--
WHY THIS EXISTS (comments are for people; the AI may ignore them)

Every new project used to hand-build a devcontainer, and Claude sign-in/history
were lost on rebuild until someone discovered the host bind-mount fix. This kit
makes that repeatable and puts the shared parts in one place. The bootstrapping
AI is not in a devcontainer and is not configured yet, so everything it needs is
plain files under ~/develop and needs only git, python3, and network access.
The interview is the AI's job (it can adapt); typing the files is the script's
job (it is exact and automatable). The "wait for rebuild" rule exists because an
AI that keeps going after editing .devcontainer/ works against an environment
that does not have the new tool yet.
-->

## 1. Get the kit

```bash
if [ -d ~/develop/devcontainer-kit ]; then git -C ~/develop/devcontainer-kit pull --ff-only
else git clone git@github.com:mattscilipoti/devcontainer-kit.git ~/develop/devcontainer-kit; fi
```
Check `git`, `python3` and `docker` exist on the host (`command -v`). If one is
missing, tell the user what to install and stop. Read
`~/develop/devcontainer-kit/README.md`.

## 2. Ask the user

Ask these, with the stated defaults, using your question tool if you have one.
Recommend the default; do not make the user research it. Do not assume Ruby or
Rails: the first answer decides.

1. **Project folder and name.** Default: the folder name. The name also names
   the Claude folder `~/.claude-devcontainers/<name>`.
2. **What kind of project?** Pick one or more: `go`, `ruby`, `rails`, `web`
   (HTML/CSS/JS). They combine. If none fit, stop and offer to add a stack
   (copy the nearest `stacks/*.json`); do not improvise a Dockerfile.
3. **If `rails`:** database `sqlite` (default) or `postgres`; will it have
   browser/system tests (adds Chromium)?
4. **If `web` (or Node is wanted):** Node **LTS** (default) or latest, or a
   specific major. Recommend LTS: it gets about 30 months of fixes and matches
   what hosting platforms support; "Current" releases can end within a year.
5. **Does it need Docker inside the devcontainer?** Default no (Postgres adds it
   automatically).

Versions are not asked: the kit uses the latest supported release of each, looked
up at run time. Ruby comes from the Ruby team's `rubylang/ruby` image; say so to
anyone who asks why.

## 3. Generate

```bash
cd ~/develop/devcontainer-kit
script/new-devcontainer --project-dir <dir> --stacks <comma list> --name <name> \
    [--node lts|latest|<major>] [--database postgres] [--browser-tests] [--docker-in-docker] --dry-run
```
Run with `--dry-run` first, then without. It refuses to overwrite existing files;
if the project already has a `.devcontainer/`, show the user the difference and
ask before using `--force`. Dependencies go in the devcontainer, never into the
workspace: do not `apt install`, `gem install`, or download tools into the
project folder or the host to make the project run.

## 4. Review and explain

Show the user the generated `devcontainer.json`, `Dockerfile`, and
`versions.json`, and say in a few lines what will be installed and at which
versions. Do not commit unless asked.

## 5. Stop and wait for the rebuild

Tell the user to open the project in VS Code and run **Dev Containers: Rebuild
Container** (or "Reopen in Container"). **Stop and wait.** The first container
start creates `~/.claude-devcontainers/<name>/` and the shared folder.
Claude Code needs one sign-in the first time.

## 6. Check the dependencies

When the user says the rebuild finished, run `.devcontainer/check-dependencies.sh`
inside the container and report each version. Fix failures in `.devcontainer/`
(never by hand in the container), then go back to step 5.

## 7. Later changes

Any time a dependency is added or changed: edit `.devcontainer/` (and
`.devcontainer/versions.json` if a pinned language version changes), tell the
user what changed, wait for the rebuild, then run `check-dependencies.sh`. This
rule is already written into the project's `AGENTS.md`.

## 8. Scheduled checks (offer; confirm before changing GitHub)

The project gets `.github/dependabot.yml` and `.github/workflows/scheduled-checks.yml`
(weekly out-of-date versions and Trivy security scans; no AI usage). They take
effect once pushed. With the user's go-ahead, enable alerts and security updates:

```bash
gh api -X PUT repos/<owner>/<repo>/vulnerability-alerts
gh api -X PUT repos/<owner>/<repo>/automated-security-fixes
```

## 9. Moving an older project

If a project already keeps Claude state in a Docker volume or loses it on rebuild,
use `prompts/move-claude-config-to-host-bind-mount.md`; the generated files
already contain the bind mount, so only the data copy applies.
