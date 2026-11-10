#!/usr/bin/env bash
# Install agent skills listed in `skills-lock.json` into `~/.agents/skills/`.
#
# Used when a fresh clone does not have local skills installed (the
# `.agents/` directory is gitignored). Reading `skills-lock.json` keeps the
# install reproducible: each skill is fetched from `mattpocock/skills` and its
# SKILL.md copied under `~/.agents/skills/<skill>/`.
set -euo pipefail

SKILLS_FILE="${SKILLS_FILE:-skills-lock.json}"
SOURCE="mattpocock/skills"
DEST_ROOT="${HOME}/.agents/skills"

if [ ! -f "$SKILLS_FILE" ]; then
  echo "skills-lock.json not found at ${SKILLS_FILE:-<repo-root>/skills-lock.json}" >&2
  exit 1
fi

mkdir -p "$DEST_ROOT"

# Extract skill names: {"name1": {"source": "...", "skillPath": "..."}, ...}
mapfile -t SKILLS < <(jq -r '.skills | keys[]' "$SKILLS_FILE")

for SKILL in "${SKILLS[@]}"; do
  echo "Installing ${SKILL} ..."
  SN=$(jq -r --arg name "$SKILL" '.skills[$name].skillPath' "$SKILLS_FILE")
  SNAME=$(basename "$(dirname "$SN")")
  set_file=$(jq -r --arg name "$SKILL" '.skills[$name].source' "$SKILLS_FILE")
  if [ "$set_file" != "mattpocock/skills" ]; then
    echo "  ignoring skill ${SKILL}: unknown source $(jq -r --arg name "$SKILL" '.skills[$name].source' "$SKILLS_FILE")" >&2
    continue
  fi
  mkdir -p "${DEST_ROOT}/${SNAME}"
  pnpm dlx skills add "$SOURCE" --path "${DEST_ROOT}/${SNAME}" -s "$SNAME" --full-depth --copy
done

echo "Done. Skills installed under ${DEST_ROOT}"
