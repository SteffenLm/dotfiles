#!/usr/bin/env bash
# Verify the local one-question-at-a-time fork of the grilling skill.
set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SKILL="$REPO/agents/.agents/skills/productivity/grilling/SKILL.md"

fail() {
  printf 'grilling: %s\n' "$1" >&2
  exit 1
}

[ -f "$SKILL" ] || fail "missing $SKILL"
grep -q 'local-fork: "one-question-at-a-time"' "$SKILL" ||
  fail "local fork marker missing"
grep -qi 'one at a time' "$SKILL" ||
  fail "one-at-a-time rule missing"

if grep -qi 'whole frontier in one round' "$SKILL"; then
  fail "batch instruction still present"
fi

for wrapper in \
  agents/.agents/skills/productivity/grill-me/SKILL.md \
  agents/.agents/skills/engineering/grill-with-docs/SKILL.md; do
  [ -f "$REPO/$wrapper" ] || fail "missing $wrapper"
  grep -q '"grilling"' "$REPO/$wrapper" ||
    fail "$wrapper: no longer calls grilling"
done

printf 'grilling: local fork intact\n'
