#!/usr/bin/env bash
#
# setup-project.sh
#
# One-time template setup: sets this project's identity - org and name -
# across README.md, CONTRIBUTING.md, package.json, and package-lock.json,
# then deletes itself. Run this once, right after generating a new project
# from this template:
#
#   ./setup-project.sh
#
# This deliberately does NOT touch the example GameMaker project (the
# `grid-utility-professional/` folder at the repo root). That folder holds
# a real, working example game, not a name to find-and-replace - replace it
# yourself: delete `grid-utility-professional/` and put your own GameMaker
# project in its place. If you rename the folder, also update the
# `working-directory: ./grid-utility-professional` lines in `preview.yaml`'s
# `gm-cli-tests` and `gm-cli-compile` jobs (and the `.config/gm-fail.sh`
# invocation in the same file) to match - this script does not do that for
# you.
#
# Two things are asked for up front, not one: the GitHub org/user the new
# project lives under, and the project's own name. Both are needed because
# package.json's `homepage`/`bugs.url`/`repository.url` fields, and every
# "NinjaMonkeyGames/gamemaker-project-template" mention in README.md and
# CONTRIBUTING.md, encode *both* - a blind find-and-replace of just the old
# project name would leave the org half of every URL and path pointing at
# this template's own org.
#
# package.json and package-lock.json are rewritten with Node (`node -e`,
# parsing and re-serializing the JSON) rather than a text substitution -
# once the org is being set too, several fields need their *values*
# reconstructed from org+name (the URLs), not just an old substring
# swapped for a new one, and JSON is worth parsing properly rather than
# pattern-matched. package.json's `name`, `version` (reset to `0.1.0` -
# see note below), `description`, `homepage`, `bugs.url`, `repository.url`,
# and `author` are all set; package-lock.json's top-level and
# `packages[""]` `name`/`version` are kept in sync with it, since `npm ci`
# refuses to run if they drift apart.
#
# Resetting `version` to `0.1.0` is safe regardless of how many releases
# the template itself has been through: GitHub's "Use this template" flow
# starts the new repo from a single fresh commit with no history and no
# tags, and semantic-release computes the next real version from git tags
# in *this* repo's own history (there aren't any yet), not from
# package.json's version field - whatever that field says here is
# overwritten by @semantic-release/npm the moment a real release runs.
#
# README.md and CONTRIBUTING.md get two plain-text passes, not a
# JSON-shaped one: every case-insensitive mention of "NinjaMonkeyGames" is
# replaced with the new org, and every mention of
# "gamemaker-project-template" is replaced with the new project name.
# Both old strings are hardcoded here rather than read from a file, since
# neither file has a canonical "current value" field the way package.json
# does.
#
# This script does NOT upload anything to GitHub, including branch
# protection rulesets. That was tried and pulled back out: it depended on
# the `gh` CLI being installed and already logged in on whatever machine
# ran this script, and on real usage it failed with a bare "Validation
# Failed (HTTP 422)" from GitHub's API with no clear way for the script to
# explain *why* - a failure mode that's genuinely hard to diagnose from
# inside an unattended script. Uploading a ruleset from
# `branch-protection-rules/*.json` (if that folder exists) is a manual
# step instead - see Configuration in the wiki.
#
# Only a restricted charset is accepted for the new project name (letters,
# digits, hyphens, underscores) and the new org (GitHub's own org/user
# rules: letters, digits, hyphens, no leading/trailing hyphen, 39 chars
# max) - both so the substitutions above can stay plain literal replaces,
# and so the org ends up being something that can actually exist as a
# GitHub org/user name.
#
# Last step: seeds .git/COMMIT_EDITMSG with an example commit message in
# this repo's own conventional-commit format, so the first `git commit` run
# after setup already opens with a filled-in starting point instead of a
# blank editor.

set -euo pipefail

NAME_PATTERN='^[A-Za-z0-9_-]+$'
ORG_PATTERN='^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$'
OLD_ORG_LITERAL="NinjaMonkeyGames"
OLD_PROJECT_LITERAL="gamemaker-project-template"
TEXT_FILES=("README.md" "CONTRIBUTING.md")

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT_DIR="$(dirname "$SCRIPT_PATH")"
GIT_DIR="$ROOT_DIR/.git"

# Case-sensitive literal replace of old_str with new_str in one file, in
# place. Skips gracefully - a message, not a failure - if the file doesn't
# exist or doesn't mention old_str.
replace_literal()
{
  local old_str="$1" new_str="$2" file="$3" tmp

  if [ ! -f "$file" ]; then
    echo "  $file not found - skipping." >&2
    return
  fi

  if ! grep -qF -- "$old_str" "$file"; then
    echo "  $file doesn't mention '$old_str' - skipping." >&2
    return
  fi

  tmp="$(mktemp)"
  sed "s/${old_str}/${new_str}/g" "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  echo "  updated: $file ('$old_str' -> '$new_str')" >&2
}

# Same as replace_literal, but case-insensitive (GNU sed's "I" flag on the
# s/// command), for the org name - README.md/CONTRIBUTING.md prose isn't
# guaranteed to always spell it the same way.
replace_literal_ci()
{
  local old_str="$1" new_str="$2" file="$3" tmp

  if [ ! -f "$file" ]; then
    echo "  $file not found - skipping." >&2
    return
  fi

  if ! grep -qi -- "$old_str" "$file"; then
    echo "  $file doesn't mention '$old_str' - skipping." >&2
    return
  fi

  tmp="$(mktemp)"
  sed "s/${old_str}/${new_str}/gI" "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  echo "  updated: $file ('$old_str', any case, -> '$new_str')" >&2
}

# Rewrites package.json's identity fields from org+name, via Node rather
# than a text substitution - see the header comment for why. Skips
# gracefully if package.json doesn't exist.
update_package_json()
{
  local new_org="$1" new_name="$2" pkg_file="$ROOT_DIR/package.json"

  if [ ! -f "$pkg_file" ]; then
    echo "  package.json not found - skipping." >&2
    return
  fi

  # Single-quoted on purpose below: this is Node source, using
  # process.argv, not a shell string meant to expand.
  # shellcheck disable=SC2016
  node -e '
    const fs = require("fs");
    const [ , file, org, name ] = process.argv;
    const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
    pkg.name = name;
    pkg.version = "0.1.0";
    pkg.description = name;
    pkg.homepage = `https://github.com/${org}/${name}#readme`;
    pkg.bugs = pkg.bugs || {};
    pkg.bugs.url = `https://github.com/${org}/${name}/issues`;
    pkg.repository = pkg.repository || {};
    pkg.repository.type = pkg.repository.type || "git";
    pkg.repository.url = `git+https://github.com/${org}/${name}.git`;
    pkg.author = org;
    fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
  ' "$pkg_file" "$new_org" "$new_name"

  echo "  updated: $pkg_file (name, version, description, homepage, bugs.url, repository.url, author)" >&2
}

# Keeps package-lock.json's own name/version fields in sync with
# package.json's - `npm ci` refuses to run if they drift apart. Skips
# gracefully if package-lock.json doesn't exist.
update_package_lock_json()
{
  local new_name="$1" lock_file="$ROOT_DIR/package-lock.json"

  if [ ! -f "$lock_file" ]; then
    echo "  package-lock.json not found - skipping." >&2
    return
  fi

  # Single-quoted on purpose below: this is Node source, using
  # process.argv, not a shell string meant to expand.
  # shellcheck disable=SC2016
  node -e '
    const fs = require("fs");
    const [ , file, name ] = process.argv;
    const lock = JSON.parse(fs.readFileSync(file, "utf8"));
    lock.name = name;
    lock.version = "0.1.0";
    if (lock.packages && lock.packages[""]) {
      lock.packages[""].name = name;
      lock.packages[""].version = "0.1.0";
    }
    fs.writeFileSync(file, JSON.stringify(lock, null, 2) + "\n");
  ' "$lock_file" "$new_name"

  echo "  updated: $lock_file (name, version)" >&2
}

# Seeds .git/COMMIT_EDITMSG with an example conventional-commit message, so
# the commit that records this setup has a ready-made starting point. Uses
# a quoted heredoc ('COMMIT_MSG_EOF') so nothing in the message body is
# ever treated as shell syntax to expand or interpret.
write_commit_message()
{
  mkdir -p "$GIT_DIR"
  cat > "$GIT_DIR/COMMIT_EDITMSG" <<'COMMIT_MSG_EOF'
feat(core): example

Touched:

- template

Description:

- Example

References #1

Signed-off-by: Daniel Mallett <daniel.mallett@ninjamonkeygames.com>
COMMIT_MSG_EOF
}

main()
{
  local new_org new_name confirmation file

  read -r -p "Enter the GitHub org or user this project will live under: " new_org

  if [ -z "$new_org" ]; then
    echo "No org entered - aborting, nothing changed." >&2
    exit 1
  fi

  if ! [[ "$new_org" =~ $ORG_PATTERN ]]; then
    echo "'$new_org' isn't a valid GitHub org/user name - letters, digits, and" >&2
    echo "hyphens only, and it can't start or end with a hyphen. Aborting," >&2
    echo "nothing changed." >&2
    exit 1
  fi

  read -r -p "Enter the new project name: " new_name

  if [ -z "$new_name" ]; then
    echo "No name entered - aborting, nothing changed." >&2
    exit 1
  fi

  if ! [[ "$new_name" =~ $NAME_PATTERN ]]; then
    echo "'$new_name' isn't a valid name - only letters, digits, hyphens" >&2
    echo "and underscores are allowed - aborting, nothing changed." >&2
    exit 1
  fi

  echo ""
  echo "This will set the project's identity to '${new_org}/${new_name}' in:"
  echo "  - package.json (name, version, description, homepage, bugs.url,"
  echo "    repository.url, author)"
  echo "  - package-lock.json (name, version)"
  echo "  - README.md and CONTRIBUTING.md ('$OLD_ORG_LITERAL' -> '$new_org',"
  echo "    '$OLD_PROJECT_LITERAL' -> '$new_name')"
  echo ""
  echo "It will NOT touch the example GameMaker project"
  echo "(grid-utility-professional/) - replace that yourself with your own"
  echo "project, and update preview.yaml's working-directory paths to match"
  echo "if you rename its folder."
  echo ""
  read -r -p "Type CONFIRM to proceed: " confirmation

  if [ "$confirmation" != "CONFIRM" ]; then
    echo "Not confirmed - aborting, nothing changed." >&2
    exit 1
  fi

  echo ""
  echo "Updating package.json..."
  update_package_json "$new_org" "$new_name"

  echo ""
  echo "Updating package-lock.json..."
  update_package_lock_json "$new_name"

  echo ""
  echo "Updating README.md and CONTRIBUTING.md..."
  for file in "${TEXT_FILES[@]}"; do
    replace_literal_ci "$OLD_ORG_LITERAL" "$new_org" "$ROOT_DIR/$file"
    replace_literal "$OLD_PROJECT_LITERAL" "$new_name" "$ROOT_DIR/$file"
  done

  echo ""
  echo "Writing example commit message to .git/COMMIT_EDITMSG..."
  write_commit_message

  echo ""
  echo "Done."
  echo "Deleting this script..."
  rm -f "$SCRIPT_PATH"
}

main "$@"