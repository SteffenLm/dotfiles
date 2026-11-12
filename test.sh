#!/usr/bin/env bash
# One-time interactive harness for the bash + starship migration.
# Usage: ./test.sh
#   KEEP=1 ./test.sh   # keep the sandbox dir after exit

set -u

REPO=${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
LIVE=${LIVE:-$HOME/dotfiles}

STOW=$(command -v stow) || { echo "missing: stow"; exit 1; }
TMUX=$(command -v tmux) || { echo "missing: tmux"; exit 1; }
[ -d "$REPO/shell" ] || { echo "bad REPO: $REPO"; exit 1; }

TEST_PATH=/usr/local/bin:/usr/bin:/bin
sbx=$(mktemp -d "${TMPDIR:-/tmp}/bash-starship-test.XXXXXX")
TSOCK=dotfiles-test
cleanup() {
  "$TMUX" -L "$TSOCK" kill-server 2>/dev/null || true
  if [ "${KEEP:-0}" = 1 ]; then
    echo "sandbox kept: $sbx"
    return
  fi
  rm -rf "$sbx"
}
trap cleanup EXIT INT TERM

# Keep Ubuntu's /etc/bash.bashrc sudo hint out of captured output.
: > "$sbx/.hushlogin"
: > "$sbx/.sudo_as_admin_successful"

# Simulate the custom/.profile.d layout without touching live.
mkdir -p "$sbx/.profile.d" "$sbx/.bashrc.d" "$sbx/.local/bin"
for f in proxy open-code nix-os; do
  src="$LIVE/custom/.profile.d/$f"
  [ -f "$src" ] && cp "$src" "$sbx/.profile.d/$f"
done
printf 'export TEST_PROFILE_D=loaded\n' > "$sbx/.profile.d/00-test"

# Exercise the new ~/.local/bin PATH prepend without depending on brew.
if command -v starship >/dev/null 2>&1; then
  ln -s "$(command -v starship)" "$sbx/.local/bin/starship"
else
  cat > "$sbx/.local/bin/starship" <<'SH'
#!/bin/sh
[ "$1" = init ] && [ "$2" = bash ] && printf 'export STARSHIP_SHELL=bash\n'
SH
  chmod +x "$sbx/.local/bin/starship"
fi

# Extra edge cases for manual/auto checks.
printf 'export SPACE_OK=1\n' > "$sbx/.bashrc.d/with space"
ln -s "$sbx/does-not-exist" "$sbx/.bashrc.d/zz-dangling"

cd "$REPO" || exit 1
echo "stowing into $sbx ..."
"$STOW" --no-folding -t "$sbx" shell tmux starship pkg mise eza zoxide fzf ubuntu || exit 1

pass=0
fail=0
ck() {
  if [ "$2" = "$3" ]; then
    printf 'PASS  %s\n' "$1"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s\n        want [%s]\n        got  [%s]\n' "$1" "$2" "$3"
    fail=$((fail + 1))
  fi
}
run() { HOME="$sbx" PATH="$TEST_PATH" "$@" 2>"$sbx/err"; }
errs() { grep -vE 'cannot set terminal process group|no job control in this shell' "$sbx/err" 2>/dev/null; }
tm() { HOME="$sbx" PATH="$TEST_PATH" SHELL=/bin/bash "$TMUX" -L "$TSOCK" "$@"; }

echo
echo "--- automatic checks ---"

o=$(run bash -l -i -c 'printf "%s|%s|%s" "${__DOTFILES_PROFILE_D_LOADED:-}" "${TEST_PROFILE_D:-}" "${STARSHIP_SHELL:-}"')
ck ".bash_profile loads profile.d once + starship" "1|loaded|bash" "$o"
ck "login stderr clean" "" "$(errs)"

o=$(run bash -i -c 'printf "%s|%s|%s" "${__DOTFILES_PROFILE_D_LOADED:-}" "${TEST_PROFILE_D:-}" "${STARSHIP_SHELL:-}"')
ck "non-login interactive loads profile.d + starship" "1|loaded|bash" "$o"
ck "terminal stderr clean" "" "$(errs)"

o=$(run bash -c 'printf "%s" "${TEST_PROFILE_D:-unset}"')
ck "non-interactive ignores rc" "unset" "$o"

o=$(run bash -i -c 'alias update-os >/dev/null 2>&1 && printf yes || printf no')
ck "update-os alias present" "yes" "$o"

o=$(run bash -i -c 'pkg present jq >/dev/null 2>&1 && printf yes || printf no')
ck "pkg present works" "yes" "$o"

o=$(run bash -i -c 'command -v z >/dev/null 2>&1 && command -v zi >/dev/null 2>&1 && command -v zd >/dev/null 2>&1 && printf yes || printf no')
ck "zoxide z/zi/zd present" "yes" "$o"

o=$(run bash -i -c 'bind -X 2>/dev/null | grep -cE "C-r|C-t"')
ck "fzf Ctrl-R/Ctrl-T bound" "2" "$o"

o=$(run bash -i -c 'bind -s 2>/dev/null | grep -cF "\\ec"')
ck "fzf Alt-C bound" "1" "$o"

if [ -e "$sbx/.bashrc.d/fzf" ]; then
  ck "fzf snippet stowed" "present" "present"
else
  ck "fzf snippet stowed" "present" "missing"
fi

o=$(run bash -i -c 'alias ls 2>/dev/null')
ck "eza ls alias" "alias ls='eza -lh --group-directories-first --icons=auto'" "$o"

o=$(run bash -i -c 'alias lsa 2>/dev/null')
ck "eza lsa alias" "alias lsa='ls -a'" "$o"

o=$(run bash -i -c 'alias cd 2>/dev/null')
ck "zoxide cd alias" "alias cd='zd'" "$o"

o=$(run bash -i -c 'cd /tmp && pwd')
ck "cd real dir uses builtin" "/tmp" "$o"

o=$(run bash -i -c 'case ":$PATH:" in *":$HOME/.local/bin:"*) printf yes ;; *) printf no ;; esac')
ck "local bin on PATH" "yes" "$o"

if [ ! -e "$sbx/packages.list" ]; then
  ck "packages.list not stowed" "absent" "absent"
else
  ck "packages.list not stowed" "absent" "present"
fi

o=$(run bash -i -c 'printf "%s" "${SPACE_OK:-none}"')
ck "path with spaces sourced" "1" "$o"
ck "dangling symlink silent" "" "$(errs)"

o=$(run bash -i -c 'printf "%s" "${STARSHIP_SHELL:-none}"')
ck "starship optional init ran" "bash" "$o"

o=$(PATH=/usr/bin:/bin HOME="$sbx" SNIPPET="$sbx/.bashrc.d/starship" bash -c '. "$SNIPPET" && printf ok' 2>"$sbx/err")
ck "missing starship is silent" "ok" "$o"
ck "missing starship stderr clean" "" "$(errs)"

o=$(PATH=/usr/bin:/bin HOME="$sbx" SNIPPET="$sbx/.bashrc.d/mise" bash -c '. "$SNIPPET" && printf ok' 2>"$sbx/err")
ck "missing mise is silent" "ok" "$o"
ck "missing mise stderr clean" "" "$(errs)"

echo
echo "--- tmux checks (isolated socket: $TSOCK) ---"
tmux -L "$TSOCK" kill-server 2>/dev/null || true
if tm new-session -d 2>"$sbx/tmux.err"; then
  ck "tmux: starts with sandbox config" "ok" "ok"
else
  ck "tmux: starts with sandbox config" "ok" "failed: $(cat "$sbx/tmux.err")"
fi

ck "tmux: panes use bash" "bash" "$(tm list-panes -F '#{pane_current_command}' 2>/dev/null | head -1)"
ck "tmux: prefix" "C-Space" "$(tm show-options -gv prefix 2>/dev/null)"
ck "tmux: prefix2" "C-b" "$(tm show-options -gv prefix2 2>/dev/null)"
ck "tmux: base-index 1" "1" "$(tm show-options -gv base-index 2>/dev/null)"
ck "tmux: pane-base-index 1" "1" "$(tm show-options -gwv pane-base-index 2>/dev/null)"
ck "tmux: status on top" "top" "$(tm show-options -gv status-position 2>/dev/null)"
ck "tmux: history-limit 50000" "50000" "$(tm show-options -gv history-limit 2>/dev/null)"
ck "tmux: detach-on-destroy off" "off" "$(tm show-options -gv detach-on-destroy 2>/dev/null)"
ck "tmux: mouse on" "on" "$(tm show-options -gv mouse 2>/dev/null)"
ck "tmux: mode-keys vi" "vi" "$(tm show-options -gwv mode-keys 2>/dev/null)"
ck "tmux: default-terminal" "tmux-256color" "$(tm show-options -gv default-terminal 2>/dev/null)"
ck "tmux: no plugin declarations" "0" "$(tm show-options -g 2>/dev/null | grep -c '@plugin' || true)"
ck "tmux: q reloads config" "1" "$(tm list-keys -T prefix q 2>/dev/null | grep -c 'source-file.*config/tmux/tmux.conf' || true)"

echo
echo "RESULTS: $pass passed, $fail failed"
echo
echo "Sandbox HOME: $sbx"
echo "Entering interactive bash (non-login). Try these, then 'exit':"
echo "  echo \$STARSHIP_SHELL                # expect: bash"
echo "  echo \$TEST_PROFILE_D                # expect: loaded"
echo "  echo \$HTTP_PROXY                    # seeded from custom/.profile.d/proxy"
echo "  alias update-os                      # distro-specific pkg upgrade"
echo "  pkg present jq                       # expect: jq: installed"
echo "  alias ls                             # expect: eza -lh ..."
echo "  type z zd                            # zoxide functions"
echo "  cd /tmp && pwd                       # real dir uses builtin cd"
echo "  echo \$__DOTFILES_PROFILE_D_LOADED   # expect: 1"
echo "  env -u __DOTFILES_PROFILE_D_LOADED bash -l   # fresh login in sandbox"
echo "  env -u __DOTFILES_PROFILE_D_LOADED bash      # fresh terminal in sandbox"
echo
echo "tmux (isolated server, sandbox config, socket '$TSOCK'):"
echo "  tmux -L $TSOCK ls                      # server is already running"
echo "  tmux -L $TSOCK attach                  # enter the Omarchy tmux config"
echo "  tmux -L $TSOCK show-options -gv prefix # expect: C-Space"
echo "  tmux -L $TSOCK kill-server             # optional, cleanup does it anyway"
echo "  # inside: prefix q reloads; prefix c opens window 1 (1-based); status is on top"
echo

HOME="$sbx" bash -i

echo
echo "sandbox shell exited."
