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
  omarchy   pacman-based, uses omarchy-update

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
    ubuntu | cachyos | omarchy)
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

packages=()
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%%#*}
  line=${line#"${line%%[![:space:]]*}"}
  line=${line%"${line##*[![:space:]]}"}
  [ -n "$line" ] || continue
  packages+=("$line")
done < "$REPO/packages.list"

if [ ${#packages[@]} -eq 0 ]; then
  printf 'install.sh: packages.list is empty\n' >&2
  exit 1
fi

printf 'Installing for %s%s\n' "$distro" "$([ "$dry_run" = 1 ] && printf ' (dry run)')"

pkg update
pkg install stow
pkg install "${packages[@]}"

if [ "$do_stow" = 0 ]; then
  printf '\nSkipping backup and stow (--no-stow).\n'
  exit 0
fi

if [ "$dry_run" = 0 ] && ! command -v stow >/dev/null 2>&1; then
  printf 'install.sh: stow is still not on PATH after installation\n' >&2
  exit 1
fi

backup_existing() {
  local timestamp backup_dir file target found=0

  timestamp=$(date +%Y%m%d-%H%M%S)
  backup_dir="$HOME/.dotfiles-backup-$timestamp"

  for file in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" \
    "$HOME/.tmux.conf" "$HOME/.zshenv" "$HOME/.zshrc" \
    "$HOME/.config/tmux/tmux.conf" \
    "$HOME/.config/dotfiles/pkg-backend.sh"; do
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

cd "$REPO"
run stow --no-folding -t "$HOME" shell tmux starship pkg mise eza zoxide "$distro"

if [ "$dry_run" = 0 ]; then
  cat <<'EOF'

Next steps:
  1. Start a fresh login shell: exec bash -l
  2. Verify: type pkg; type update-os; type z; alias ls; pkg present tmux
  3. After verifying, switch the login shell: chsh -s /usr/bin/bash
EOF
fi
