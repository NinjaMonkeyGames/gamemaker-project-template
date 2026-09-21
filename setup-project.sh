#!/usr/bin/env bash
#
# setup-project.sh
#
# One-time template setup: renames every occurrence of the placeholder
# project name "grid-utility-professional" - in file CONTENTS, file NAMES,
# and directory NAMES - to whatever this new project should actually be
# called, then deletes itself. Run this exactly once, right after cloning
# this template to start a new game:
#
#   ./setup-project.sh
#
# Both content and paths need renaming, not just content: this repo's own
# CI (preview.yaml's gm-cli-tests/gm-cli-compile jobs, for one) sets
# `working-directory: ./grid-utility-professional` - updating file
# contents alone would leave those paths pointing at a directory that no
# longer exists under its old name, and renaming paths alone would leave
# every reference to the old path dangling instead.
#
# Two things are excluded from every pass, and both are structural
# necessities rather than convenience exceptions:
#   - .git/ - it's git's own internal object database, not "your files".
#     A text/rename pass through it would corrupt the repository itself,
#     unrelated to what this script is actually for.
#   - This script's own file - it necessarily contains the placeholder
#     string in its own comments and instructions (as you're reading right
#     now), and it deletes itself once it's done regardless, so rewriting
#     its own content first would be pointless at best.
#
# Binary files are skipped during the CONTENT replacement pass specifically
# (detected via the same "does this file have a NUL byte" idea git/grep use
# internally, through `grep -Iq`) - not a quiet loophole in "no exceptions",
# but because a text substitution on binary bytes (a sprite PNG, an audio
# file) doesn't rename anything inside it, it corrupts it. Any binary file
# whose NAME contains the placeholder is still renamed - this only ever
# affects file content.
#
# Only a restricted charset - letters, digits, hyphens and underscores, the
# same shape as the placeholder name itself - is accepted for the new name.
# That isn't an arbitrary restriction: it sidesteps every sed/regex special
# character a freeform name could otherwise contain, so the substitution
# below can stay a plain literal replace instead of a hand-rolled escaping
# scheme, and a project name built from anything outside that charset would
# cause its own problems elsewhere anyway (GameMaker project files, CI
# working-directory paths, shell-quoting in this repo's own other scripts).
#
# Last step: seeds .git/COMMIT_EDITMSG with an example commit message in
# this repo's own conventional-commit format, so the first `git commit` run
# after setup (committing the rename itself) already opens with a filled-in
# starting point instead of a blank editor - `git commit` uses that file as
# its default message body whenever one isn't given some other way (-m,
# --amend, etc.), same as when a commit is interrupted and resumed.

set -euo pipefail

OLD_NAME="grid-utility-professional"
NAME_PATTERN='^[A-Za-z0-9_-]+$'

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT_DIR="$(dirname "$SCRIPT_PATH")"
GIT_DIR="$ROOT_DIR/.git"

# Decides whether a file's content is worth scanning for the placeholder:
# `grep -Iq ''` matches (exit 0) for any ordinary text file - the pattern is
# empty, so it matches trivially - but -I makes grep treat a binary file as
# a non-match regardless, the same "NUL byte means binary" idea git/grep
# use internally. An empty file also comes back as a non-match here, since
# there's no line for even an empty pattern to match against; that's fine,
# since an empty file has nothing to replace either way.
has_scannable_content()
{
  grep -Iq '' "$1" 2>/dev/null
}

# Prints every file path under $ROOT_DIR, skipping .git/ (pruned so it's
# never even descended into, not just filtered afterwards) and this
# script's own file.
collect_content_files()
{
  find "$ROOT_DIR" -path "$GIT_DIR" -prune -o -type f -not -path "$SCRIPT_PATH" -print
}

# Replaces every literal occurrence of oldName with newName in the contents
# of every scannable (non-binary, non-empty) file under rootDir. Prints one
# line per file changed. Echoes the count on its own final line so the
# caller can capture it.
replace_in_file_contents()
{
  local old_name="$1" new_name="$2" file changed=0
  while IFS= read -r file; do
    has_scannable_content "$file" || continue
    grep -qF "$old_name" "$file" || continue
    local tmp
    tmp="$(mktemp)"
    sed "s/${old_name}/${new_name}/g" "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
    changed=$((changed + 1))
    echo "  updated: $file" >&2
  done < <(collect_content_files)
  echo "$changed"
}

# Prints every path under $ROOT_DIR, deepest first (find -depth, so a
# directory rename can never invalidate a child path this function hasn't
# reached yet), skipping .git/ and this script's own file. -depth and
# -prune don't compose - GNU find documents that -prune has no effect once
# -depth is also given, confirmed directly before writing this - so .git is
# filtered in the loop below instead of pruned here.
collect_paths_deepest_first()
{
  find "$ROOT_DIR" -depth -print
}

# Renames every file/directory under dir whose own name (not its full path)
# contains oldName. Prints one line per path renamed, and echoes the count
# on its own final line so the caller can capture it.
rename_matching_paths()
{
  local old_name="$1" new_name="$2" path base dir new_path renamed=0
  while IFS= read -r path; do
    [ "$path" = "$ROOT_DIR" ] && continue
    [ "$path" = "$SCRIPT_PATH" ] && continue
    case "$path" in
      "$GIT_DIR"|"$GIT_DIR"/*) continue ;;
    esac
    base="$(basename "$path")"
    case "$base" in
      *"$old_name"*) : ;;
      *) continue ;;
    esac
    dir="$(dirname "$path")"
    new_path="$dir/${base//$old_name/$new_name}"
    mv "$path" "$new_path"
    echo "  renamed: $path -> $new_path" >&2
    renamed=$((renamed + 1))
  done < <(collect_paths_deepest_first)
  echo "$renamed"
}

# Seeds .git/COMMIT_EDITMSG with an example conventional-commit message, so
# the commit that records this rename has a ready-made starting point. Uses
# a quoted heredoc ('COMMIT_MSG_EOF') so nothing in the message body - the
# blank lines, the leading "- " list markers, the "#1" issue reference - is
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
  local new_name confirmation files_changed paths_renamed

  read -r -p "Enter the new project name (replaces every '$OLD_NAME'): " new_name

  if [ -z "$new_name" ]; then
    echo "No name entered - aborting, nothing changed." >&2
    exit 1
  fi

  if [ "$new_name" = "$OLD_NAME" ]; then
    echo "New name is identical to the old one - nothing to do."
    exit 0
  fi

  if ! [[ "$new_name" =~ $NAME_PATTERN ]]; then
    echo "'$new_name' isn't a valid name - only letters, digits, hyphens" >&2
    echo "and underscores are allowed - aborting, nothing changed." >&2
    exit 1
  fi

  echo ""
  echo "This will replace every occurrence of '$OLD_NAME' with '$new_name'"
  echo "in file contents, and rename every file/directory whose name contains"
  echo "'$OLD_NAME', across the whole project (except .git/ and this script)."
  echo ""
  read -r -p "Type CONFIRM to proceed: " confirmation

  if [ "$confirmation" != "CONFIRM" ]; then
    echo "Not confirmed - aborting, nothing changed." >&2
    exit 1
  fi

  echo ""
  echo "Replacing file contents..."
  files_changed="$(replace_in_file_contents "$OLD_NAME" "$new_name")"

  echo ""
  echo "Renaming files and directories..."
  paths_renamed="$(rename_matching_paths "$OLD_NAME" "$new_name")"

  echo ""
  echo "Writing example commit message to .git/COMMIT_EDITMSG..."
  write_commit_message

  echo ""
  echo "Done: $files_changed file(s) updated, $paths_renamed path(s) renamed."
  echo "Deleting this script..."
  rm -f "$SCRIPT_PATH"
}

main "$@"