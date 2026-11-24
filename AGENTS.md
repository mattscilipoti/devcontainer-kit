# Rules for AI assistants working on devcontainer-kit

These apply to every AI model and tool in this repo. Start with
[HANDOFF.md](HANDOFF.md) for where things stand, then [README.md](README.md) and
[PROMPT.md](PROMPT.md).

- **This repo is the kit, not a project.** It generates devcontainers for other
  projects. Changes here reach every project that uses it, so keep stacks small
  and check a change by generating into a scratch folder (`script/new-devcontainer
  --project-dir /tmp/x --stacks ...`), not by editing a real project.
- **Latest releases, looked up, never remembered.** Versions come from
  `script/latest-versions` (endoflife.date, RubyGems, Docker Hub). Do not hard-code
  a version in a stack or template.
- **Debian slim, not Ubuntu, for every stack and image.** The owner strongly prefers
  it, and Ubuntu's `chromium` is an unusable snap stub in containers. Do not add an
  Ubuntu path without the owner asking.
- **Composition uses standard Dev Container Features.** Prefer an official Feature
  or image over custom install steps; the owner wants industry-standard parts that
  are kept up to date by their maintainers. Add custom Dockerfile steps only when
  no Feature or image covers it, and say why in a comment.
- **Dependencies belong to the devcontainer.** After a change that affects a
  generated devcontainer, tell the owner, wait for them to rebuild a project
  using it, then run its `check-dependencies.sh`.
- **Automate before documenting.** If a step can be a script, make it one; the
  README covers only what cannot be scripted.
- **Scheduled checks cost no AI usage.** Use Dependabot, Trivy, and plain scripts.
  Anything that would use AI on a schedule runs weekly, not per commit.
- **Names say what happens.** Name functions and scripts for what they do.
- **Explain why in comments**, in prompts and templates, for the owner. Ask before
  anything outward-facing (pushing, changing a GitHub repo's settings).
- **Rules for AI are for every model:** write them here, not in a tool-specific
  file, unless the owner names a tool.
