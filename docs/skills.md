# Agent skills (`agents` package)

This document covers the `agents` stow package: where skills live, which source
OpenCode loads when IDs collide, and how to update the vendored Matt Pocock
collection without losing the local `grilling` fork.

## Layout

The package mirrors `~/.agents/skills`:

```
agents/
├── .agents/
│   └── skills/
│       ├── engineering/     # vendored from mattpocock/skills
│       └── productivity/    # vendored from mattpocock/skills
├── .stow-local-ignore       # keeps scripts and READMEs out of $HOME
├── check-grilling.sh        # local-fork guard
└── update.sh                # upstream sync helper
```

Stow it with the rest of the shared packages:

```sh
cd ~/dotfiles
stow --no-folding -t "$HOME" agents
```

`--no-folding` creates real directories and per-file symlinks, so the vendored
skills coexist with machine-local skill symlinks already in `~/.agents/skills`.
`install.sh` includes `agents` in its stow list. The scripts and the upstream
category READMEs stay in the repo; `.stow-local-ignore` prevents stow from
linking them into the home directory.

## Discovery and precedence

OpenCode discovers skills by ID: a directory containing `SKILL.md`, or a
root-level `*.md` file. When two sources define the same ID, the source
registered later wins. Skill bodies are **not** merged.

| Precedence | Source |
|---|---|
| lowest | built-in skills |
| | `~/.claude/skills`, then project `.claude/skills` |
| | `~/.agents/skills`, then project `.agents/skills` |
| | `~/.config/opencode/skills` |
| | project `.opencode/skills` |
| highest | `skills` array in `opencode.json(c)` |

`~/.agents/skills` is the canonical home for these skills, but a copy in
`~/.config/opencode/skills` would shadow it. Keep one copy; do not install the
same skill in both places.

## Local fork: `grilling`

Upstream changed `grilling` from one question at a time to round-by-round
"frontier" interviews in commit `a4b2009a1` (2026-07-16). The last
one-question-at-a-time version is `170ad4865` (2026-07-13).

The vendored copy keeps the old interview rhythm while retaining newer upstream
improvements ("yes" accepts the recommendation, sub-agent fact-finding). Its
frontmatter carries:

```yaml
metadata:
  local-fork: "one-question-at-a-time"
```

`grill-me` and `grill-with-docs` call the skill by ID (`"grilling"`), so they
inherit the fork automatically. `agents/check-grilling.sh` enforces the
invariant before a commit.

## Why not `AGENTS.md`

`AGENTS.md` files are concatenated: global first, then project files, then
configured `instructions`. OpenCode does not resolve conflicts between them.
A global "ask one question at a time" line would sit next to the skill body's
"ask the whole frontier in one round" with no defined winner.

`AGENTS.md` is for additive rules (package manager, test commands, safety
constraints), not skill overrides. OpenCode V2 also ignores `CLAUDE.md`; the
global file is `~/.config/opencode/AGENTS.md`.

The skill body is the deterministic place to change skill behavior.

## Updating the vendored skills

`agents/update.sh` automates steps 1-4 and prints the remaining steps:

```sh
cd ~/dotfiles
./agents/update.sh
```

Then continue with step 5. The full manual procedure is below; use it when the
script cannot run.

### Before you start

```sh
cd ~/dotfiles
git status --short
```

The output must be empty. Never update from a dirty tree.

### 1. Fetch upstream

```sh
rm -rf /tmp/mattpocock-skills
git clone --depth 1 https://github.com/mattpocock/skills /tmp/mattpocock-skills
sha=$(git -C /tmp/mattpocock-skills rev-parse --short HEAD)
echo "upstream: $sha"
```

### 2. Save your current local version

```sh
git show HEAD:agents/.agents/skills/productivity/grilling/SKILL.md \
  > /tmp/grilling.local.md
```

Git is the backup. Even if you skip this, `git show HEAD:path` works until you
commit the upstream version.

### 3. Overwrite the vendored tree

```sh
rsync -a --delete --exclude 'agents/' \
  /tmp/mattpocock-skills/skills/engineering/ \
  agents/.agents/skills/engineering/
rsync -a --delete --exclude 'agents/' \
  /tmp/mattpocock-skills/skills/productivity/ \
  agents/.agents/skills/productivity/
```

The exclusion drops the upstream `agents/openai.yaml` files. They are Codex
interface metadata; OpenCode reads only `SKILL.md`.

This intentionally deletes your local `grilling` edit. Step 5 restores it.

### 4. Check for new upstream categories

```sh
ls /tmp/mattpocock-skills/skills
```

If there is a new top-level directory besides `engineering/` and
`productivity/`, decide whether to vendor it and add it to `agents/update.sh`.

### 5. Re-apply your edit

Open:

- `/tmp/grilling.local.md` — your previous local version
- `agents/.agents/skills/productivity/grilling/SKILL.md` — the new upstream
  version

Port the one-question-at-a-time interview flow from the former into the latter.
Keep upstream's frontmatter description, new sections, and every change
unrelated to the interview mechanics. Preserve the `local-fork` marker.

Use the **Prompt: re-apply the local edit** below, or do it by hand.

### 6. Run the deterministic check

```sh
./agents/check-grilling.sh
```

It must print `grilling: local fork intact`. Do not continue if it fails.

### 7. Review the net diff

```sh
git diff --stat
git diff -- agents/.agents/skills/productivity/grilling
```

Because your local edit cancels against the previous version, this diff is the
**upstream behavioral change**. Review the other changed skills too, at least
the ones you use:

```sh
git diff -- agents/.agents/skills/engineering/tdd
git diff -- agents/.agents/skills/productivity/grill-me
```

### 8. Restow

```sh
stow -R --no-folding -t "$HOME" agents
```

This links new skills and refreshes the package. Note that Stow only scans the
current installation image when unstowing, so a skill directory removed
upstream can leave a dangling link behind. Remove
`~/.agents/skills/<category>/<name>` manually, or run
`stow --compat -R --no-folding -t "$HOME" agents` (slower, because it scans the
whole target tree). `chkstow -b -t "$HOME"` lists dangling links. If stow
reports a conflict, inspect `~/.agents/skills/<name>` and do not overwrite an
Omarchy symlink.

### 9. Test the skill

```sh
mkdir -p /tmp/skill-test
cd /tmp/skill-test
opencode
```

Use the **Prompt: test the skill** below. You should get one question, a
recommended answer, and a wait.

### 10. Commit

```sh
git add agents
git commit -m "vendor: update mattpocock skills @ $sha"
git push   # if this repo has a remote
rm -rf /tmp/mattpocock-skills /tmp/skill-test
```

### Optional: cleaner history

Commit the upstream sync before re-applying, then commit your edit separately:

```sh
# after step 3
git commit -am "vendor: update mattpocock skills @ $sha"

# after step 5
git commit -am "local: grilling asks one question at a time"
```

Then `git diff HEAD~1 HEAD` is your local edit only, and `git diff HEAD~2 HEAD`
is the net upstream change.

## AI-assisted review

### Prompt: re-apply the local edit

```text
Read /tmp/grilling.local.md (my previous local version) and
agents/.agents/skills/productivity/grilling/SKILL.md (the new upstream
version).

Re-apply my one-question-at-a-time interview flow from the former to the
latter. Keep every other upstream change. Preserve the frontmatter
metadata.local-fork marker. Only edit the interview mechanics.
```

### Prompt: review the upstream behavior change

```text
Run `git diff -- agents/.agents/skills/productivity/grilling` and review it.

1. List every behavioral change: new, changed, or removed instructions,
   output format, required steps, and new supporting-file references.
2. Verify the local invariant: exactly one question at a time, wait for my
   answer before the next, and give a recommended answer for each.
3. Flag any instruction that still implies batching, rounds, or waiting for
   multiple answers.
4. Confirm grill-me and grill-with-docs still invoke the skill ID "grilling".

Do not edit files.
```

### Prompt: test the skill

```text
@grill-me Interview me about adding a dark-mode toggle to this project.
```

Expected: one question, a recommended answer, then a wait. If you get a
numbered batch, the skill is not fixed.

## If the check fails

| Message | Cause | Fix |
|---|---|---|
| `local fork marker missing` | Frontmatter was overwritten | Restore `metadata.local-fork`. |
| `one-at-a-time rule missing` | Local interview paragraphs were lost | Re-apply from `/tmp/grilling.local.md`. |
| `batch instruction still present` | Upstream reintroduced rounds | Replace that instruction with the one-at-a-time flow. |
| `grill-me: no longer calls grilling` | Upstream renamed or split the skill | Follow the new ID, or keep `grilling` and adjust the wrapper. |
| `grill-with-docs: no longer calls grilling` | Same as above | Same as above. |

Never commit with the check failing.

## Rollback

Before push:

```sh
git reset --hard HEAD^
stow -R --no-folding -t "$HOME" agents
```

After push:

```sh
git revert HEAD
stow -R --no-folding -t "$HOME" agents
```

## Guardrails

- `rsync --delete` silently overwrites **any** local skill edit, not just
  `grilling`. Add a marker and a check for each additional skill you modify.
- Do not run `npx skills update` against the stowed tree. It fights the
  symlinks and the local fork.
- Review `grill-me` and `grill-with-docs` on every update. They decide whether
  the local `grilling` skill is still used.
- Only `engineering/` and `productivity/` are vendored. `deprecated/`,
  `in-progress/`, and `misc/` are intentionally excluded.
- The upstream `agents/openai.yaml` interface files are excluded by
  `update.sh`; they are Codex metadata and are not used by OpenCode.

## Provenance

| Field | Value |
|---|---|
| Upstream | <https://github.com/mattpocock/skills> |
| Vendored | `skills/engineering`, `skills/productivity` |
| Last sync | 2026-11-14, upstream `5863806` |
| Local change | `productivity/grilling` asks one question at a time |
| Upstream change being reverted | `a4b2009a1` (2026-07-16) |
| Last one-at-a-time upstream | `170ad4865` (2026-07-13) |
