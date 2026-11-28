#!/usr/bin/env bash
# Runs on the HOST (devcontainer.json initializeCommand), before the container
# starts. A bind mount fails when its source folder is missing, so create them.
# The shared folder is filled by the kit's script/install-shared, not here.
set -euo pipefail

root="$HOME/.claude-devcontainers"
project_folder="$root/@@NAME@@"
shared_folder="$HOME/.ai-shared"

mkdir -p "$project_folder" "$shared_folder"

[ -f "$project_folder/README.md" ] ||
  cp .devcontainer/claude-config-README.md "$project_folder/README.md"

