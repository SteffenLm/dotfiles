#!/usr/bin/env bash
# Install the dotfiles tool set and stow this repo for one distro.
set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'EOF'
usage: ./install.sh <distro> [--dry-run] [--no-stow]

distros:
  ubuntu    apt-based
  cachyos   pacman-based

options:
  --dry-run   print package, backup, and stow commands without running them
  --no-stow   install packages but do not back up or stow
EOF
}

dry_run=0
do_stow=1
distro=

for arg in "$@"; do
  case $arg in
    --dry-run)
      dry_run=1
      ;;
    --no-stow)
      do_stow=0
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    ubuntu | cachyos)
      if [ -n "$distro" ]; then
        printf 'install.sh: more than one distro given\n' >&2
        exit 2
      fi
      distro=$arg
      ;;
    *)
      printf 'install.sh: unknown argument: %s\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$distro" ]; then
  printf 'install.sh: missing distro\n' >&2
  usage >&2
  exit 2
fi

export DOTFILES_PKG_BACKEND="$REPO/$distro/.config/dotfiles/pkg-backend.sh"
if [ ! -r "$DOTFILES_PKG_BACKEND" ]; then
  printf 'install.sh: backend not found: %s\n' "$DOTFILES_PKG_BACKEND" >&2
  exit 1
fi

if [ "$dry_run" = 1 ]; then
  export PKG_DRY_RUN=1
fi

# shellcheck source=/dev/null
. "$REPO/pkg/.bashrc.d/pkg"

run() {
  if [ "$dry_run" = 1 ]; then
    printf 'DRY:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

# Append the non-comment entries from one package list to the global array.
append_packages() {
  local file=$1 line
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%%#*}
    line=${line#"${line%%[![:space:]]*}"}
    line=${line%"${line##*[![:space:]]}"}
    [ -n "$line" ] || continue
    packages+=("$line")
  done < "$file"
}

packages=()
append_packages "$REPO/packages.list"
if [ -r "$REPO/${distro}-packages.list" ]; then
  append_packages "$REPO/${distro}-packages.list"
fi

if [ ${#packages[@]} -eq 0 ]; then
  printf 'install.sh: no packages found in packages.list or %s-packages.list\n' "$distro" >&2
  exit 1
fi

printf 'Installing for %s%s\n' "$distro" "$([ "$dry_run" = 1 ] && printf ' (dry run)')"

pkg update
pkg install stow
pkg install "${packages[@]}"

# opencode is declared in the tracked mise config rather than packages.list.
# Its npm backend needs the configured Node version first: `mise install <tool>`
# does not install dependencies from the config for scoped installs.
mise_bin=$(command -v mise || true)
if [ -z "$mise_bin" ] && [ -x "$HOME/.local/bin/mise" ]; then
  mise_bin="$HOME/.local/bin/mise"
fi
if [ -n "$mise_bin" ]; then
  mise_cmd=("$mise_bin")
elif [ "$dry_run" = 1 ]; then
  mise_cmd=(mise)
else
  printf 'install.sh: mise not found; cannot install node and opencode\n' >&2
  exit 1
fi
run "${mise_cmd[@]}" --cd "$REPO/mise/.config/mise" install node
run "${mise_cmd[@]}" --cd "$REPO/mise/.config/mise" install opencode

# Older releases installed opencode directly into ~/.local/bin; mise owns it now.
if [ -f "$HOME/.local/bin/opencode" ] &&
  [ ! -L "$HOME/.local/bin/opencode" ]; then
  run rm -f "$HOME/.local/bin/opencode"
fi

if [ "$do_stow" = 0 ]; then
  printf '\nSkipping backup and stow (--no-stow).\n'
  exit 0
fi

if [ "$dry_run" = 0 ] && ! command -v stow >/dev/null 2>&1; then
  printf 'install.sh: stow is still not on PATH after installation\n' >&2
  exit 1
fi

backup_files=(
  "$HOME/.bashrc"
  "$HOME/.profile"
  "$HOME/.bash_profile"
  "$HOME/.inputrc"
  "$HOME/.tmux.conf"
  "$HOME/.config/tmux/tmux.conf"
  "$HOME/.config/starship.toml"
  "$HOME/.config/mise/config.toml"
  "$HOME/.config/dotfiles/pkg-backend.sh"
)
if [ "$distro" = ubuntu ]; then
  backup_files+=("$HOME/.config/nix/nix.conf")
elif [ "$distro" = cachyos ]; then
  backup_files+=("$HOME/.config/alacritty/alacritty.toml")
fi

backup_existing() {
  local file target found=0

  backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

  for file in "${backup_files[@]}"; do
    [ -e "$file" ] || [ -L "$file" ] || continue

    target=$(readlink -f -- "$file" 2>/dev/null || true)
    case $file in
      "$HOME/.config/dotfiles/pkg-backend.sh")
        [ "$target" = "$REPO/$distro/.config/dotfiles/pkg-backend.sh" ] && continue
        ;;
      *)
        case $target in
          "$REPO"/*) [ -e "$target" ] && continue ;;
        esac
        ;;
    esac

    if [ "$found" = 0 ]; then
      run mkdir -p "$backup_dir"
      found=1
    fi
    run mv "$file" "$backup_dir/"
  done

  if [ "$found" = 1 ]; then
    if [ "$dry_run" = 1 ]; then
      printf 'Would back up existing config to %s\n' "$backup_dir"
    else
      printf 'Existing config backed up to %s\n' "$backup_dir"
    fi
  fi
}

backup_existing

# Legacy installs folded whole manifold directories into symlinks. With
# --no-folding, stow cannot merge multiple packages through such a link;
# dangling links are safe to replace, but valid ones may hold machine-local
# snippets and must be converted manually.
prepare_manifold_dirs() {
  local dir link
  local -a dirs=("$HOME/.bashrc.d" "$HOME/.alias.d")
  if [ "$distro" = ubuntu ]; then
    dirs+=("$HOME/.profile.d")
  fi

  for dir in "${dirs[@]}"; do
    [ -L "$dir" ] || continue

    if [ -e "$dir" ]; then
      printf 'install.sh: %s is a symlink; it must be a real directory before stowing\n' \
        "$dir" >&2
      printf 'install.sh: convert it to a manifold directory (see docs/loader-system.md)\n' >&2
      if [ "$dry_run" = 0 ]; then
        exit 1
      fi
      printf 'install.sh: dry run only; a real run would stop before stow\n' >&2
      continue
    fi

    link=$(readlink "$dir" 2>/dev/null || true)
    if [ "$dry_run" = 1 ]; then
      printf 'Would replace dangling manifold symlink %s -> %s\n' "$dir" "${link:-?}"
    else
      printf 'Replacing dangling manifold symlink %s -> %s\n' "$dir" "${link:-?}"
    fi
    run mkdir -p "$backup_dir"
    run mv "$dir" "$backup_dir/"
    run mkdir -p "$dir"
  done
}

prepare_manifold_dirs

# OpenCode owns ~/.config/opencode/cli.json; never seed or manage it here.
# Remove only legacy symlinks into this repo, including dangling ones: the
# opencode stow package no longer exists, so `readlink -f` would fail.
opencode_tui="$HOME/.config/opencode/tui.json"
if [ -L "$opencode_tui" ]; then
  opencode_tui_target=$(readlink -m -- "$opencode_tui" 2>/dev/null || true)
  case $opencode_tui_target in
    "$REPO"/*) run rm -f "$opencode_tui" ;;
  esac
fi

opencode_theme="$HOME/.config/opencode/themes/retro-82.json"
if [ -L "$opencode_theme" ]; then
  opencode_theme_target=$(readlink -m -- "$opencode_theme" 2>/dev/null || true)
  case $opencode_theme_target in
    "$REPO"/*) run rm -f "$opencode_theme" ;;
  esac
fi

stow_packages=(shell tmux starship pkg mise eza zoxide fzf agents)
case $distro in
  ubuntu)
    stow_packages+=(nix)
    ;;
  cachyos)
    stow_packages+=(alacritty)
    ;;
esac

cd "$REPO"
run stow --no-folding -t "$HOME" "${stow_packages[@]}" "$distro"

if [ "$dry_run" = 0 ]; then
  cat <<'EOF'

Next steps:
  1. Start a fresh login shell: exec bash -l
  2. Verify: type pkg; type update-os; type z; alias ls; pkg present tmux
  3. After verifying, switch the login shell: chsh -s /usr/bin/bash
EOF
  if [ "$distro" = cachyos ]; then
    printf '  4. Pick a terminal theme: alacritty-theme\n'
  fi
fi
