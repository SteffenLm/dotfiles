#!/usr/bin/env bash
# Refresh the vendored Matt Pocock skills. Review before committing.
set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"

if ! git diff --quiet || ! git diff --cached --quiet ||
  [ -n "$(git ls-files --others --exclude-standard)" ]; then
  printf 'update.sh: working tree is not clean; commit or stash first\n' >&2
  exit 1
fi

for tool in git rsync; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf 'update.sh: missing %s\n' "$tool" >&2
    exit 1
  }
done

tmp=$(mktemp -d "${TMPDIR:-/tmp}/mattpocock-skills.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM

git clone --depth 1 https://github.com/mattpocock/skills "$tmp/upstream"
sha=$(git -C "$tmp/upstream" rev-parse --short HEAD)

for category in engineering productivity; do
  [ -d "$tmp/upstream/skills/$category" ] || {
    printf 'update.sh: upstream has no skills/%s\n' "$category" >&2
    exit 1
  }
done

git show HEAD:agents/.agents/skills/productivity/grilling/SKILL.md \
  >/tmp/grilling.local.md

find agents/.agents/skills -mindepth 2 -maxdepth 2 -type d -printf '%P\n' |
  LC_ALL=C sort >"$tmp/before"

for category in engineering productivity; do
  # agents/openai.yaml is Codex interface metadata; OpenCode does not read it.
  rsync -a --delete --exclude 'agents/' \
    "$tmp/upstream/skills/$category/" \
    "agents/.agents/skills/$category/"
done

find agents/.agents/skills -mindepth 2 -maxdepth 2 -type d -printf '%P\n' |
  LC_ALL=C sort >"$tmp/after"
added=$(LC_ALL=C comm -13 "$tmp/before" "$tmp/after")
removed=$(LC_ALL=C comm -23 "$tmp/before" "$tmp/after")

if [ -n "$added" ]; then
  printf '\nAdded upstream:\n%s\n' "$added"
fi
if [ -n "$removed" ]; then
  printf '\nRemoved upstream:\n%s\n' "$removed"
  printf 'Stow may leave dangling links behind; remove the matching paths from\n'
  printf '~/.agents/skills or run stow --compat -R --no-folding -t "$HOME" agents.\n'
fi

for dir in "$tmp/upstream/skills"/*/; do
  name=$(basename "$dir")
  case $name in
    engineering | productivity) ;;
    *) printf 'note: upstream category not vendored: %s\n' "$name" ;;
  esac
done

printf '\nUpstream: %s\n' "$sha"
printf 'Previous local grilling: /tmp/grilling.local.md\n'
printf '\nNext:\n'
printf '  1. Re-apply the one-at-a-time edit to agents/.agents/skills/productivity/grilling/SKILL.md\n'
printf '  2. ./agents/check-grilling.sh\n'
printf '  3. git diff --stat && git diff -- agents/.agents/skills/productivity/grilling\n'
printf '  4. stow -R --no-folding -t "$HOME" agents\n'
printf '  5. Test with @grill-me in a fresh session\n'
printf '  6. git add agents && git commit -m "vendor: update mattpocock skills @ %s"\n' "$sha"
printf '\nSee docs/skills.md for the review checklist and AI prompts.\n'
