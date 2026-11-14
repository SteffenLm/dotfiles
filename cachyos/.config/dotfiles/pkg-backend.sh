# shellcheck shell=bash
# CachyOS/Arch backend for the dotfiles pkg dispatcher.

declare -gA PKG_MAP=(
  [build-essential]=base-devel
  [gh]=github-cli
)

declare -gA PKG_METHOD=(
  [opencode]=mise
)

_pkg_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

_pkg_run() {
  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  _pkg_sudo "$@"
}

_pkg_run_plain() {
  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

_pkg_native_name() {
  printf '%s' "${PKG_MAP[$1]:-$1}"
}

_pkg_mise_bin() {
  if command -v mise >/dev/null 2>&1; then
    command -v mise
  elif [ -x "$HOME/.local/bin/mise" ]; then
    printf '%s\n' "$HOME/.local/bin/mise"
  fi
}

_pkg_install_mise() {
  local name=$1 mise

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: mise install %s\n' "$name"
    return 0
  fi

  mise=$(_pkg_mise_bin)
  if [ -z "$mise" ]; then
    printf 'pkg: mise not found; cannot install %s\n' "$name" >&2
    return 1
  fi

  "$mise" install "$name"
}

_pkg_remove_mise() {
  local name=$1 mise

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: mise uninstall --all %s\n' "$name"
    return 0
  fi

  mise=$(_pkg_mise_bin)
  if [ -z "$mise" ]; then
    printf 'pkg: mise not found; cannot remove %s\n' "$name" >&2
    return 1
  fi

  "$mise" uninstall --all "$name"
}

_pkg_install() {
  [ $# -gt 0 ] || {
    printf 'pkg: install requires at least one package\n' >&2
    return 2
  }

  local name
  local -a natives=()
  local -a specials=()

  for name in "$@"; do
    case ${PKG_METHOD[$name]:-} in
      mise)
        specials+=("$name")
        ;;
      *)
        natives+=("$(_pkg_native_name "$name")")
        ;;
    esac
  done

  if [ ${#natives[@]} -gt 0 ]; then
    _pkg_run pacman -S --needed --noconfirm -- "${natives[@]}" || return
  fi

  for name in "${specials[@]}"; do
    _pkg_install_mise "$name" || return
  done
}

_pkg_remove() {
  [ $# -gt 0 ] || {
    printf 'pkg: remove requires at least one package\n' >&2
    return 2
  }

  local name
  local -a natives=()
  local -a specials=()

  for name in "$@"; do
    case ${PKG_METHOD[$name]:-} in
      mise)
        specials+=("$name")
        ;;
      *)
        natives+=("$(_pkg_native_name "$name")")
        ;;
    esac
  done

  if [ ${#natives[@]} -gt 0 ]; then
    _pkg_run pacman -Rns --noconfirm -- "${natives[@]}" || return
  fi

  for name in "${specials[@]}"; do
    _pkg_remove_mise "$name" || return
  done
}

_pkg_update() {
  _pkg_run pacman -Syu --noconfirm
}

_pkg_upgrade() {
  _pkg_run pacman -Syu --noconfirm
}

_pkg_search() {
  _pkg_run_plain pacman -Ss -- "$@"
}

_pkg_present() {
  [ $# -gt 0 ] || {
    printf 'pkg: present requires at least one package\n' >&2
    return 2
  }

  local name native rc=0

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: check package presence for: %s\n' "$*"
    return 0
  fi

  for name in "$@"; do
    native=$(_pkg_native_name "$name")
    if [ "$native" = base-devel ]; then
      if pacman -Qq -- base-devel >/dev/null 2>&1 ||
        pacman -Qg base-devel >/dev/null 2>&1; then
        printf '%s: installed\n' "$name"
      else
        printf '%s: missing\n' "$name"
        rc=1
      fi
    elif [ -n "${PKG_METHOD[$name]:-}" ]; then
      if command -v "$name" >/dev/null 2>&1 ||
        [ -x "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims/$name" ]; then
        printf '%s: installed\n' "$name"
      else
        printf '%s: missing\n' "$name"
        rc=1
      fi
    elif pacman -Qq -- "$native" >/dev/null 2>&1; then
      printf '%s: installed\n' "$name"
    else
      printf '%s: missing\n' "$name"
      rc=1
    fi
  done

  return "$rc"
}
