# shellcheck shell=bash
# CachyOS/Arch backend for the dotfiles pkg dispatcher.

declare -gA PKG_MAP=(
  [build-essential]=base-devel
)

# shellcheck disable=SC2034
declare -gA PKG_METHOD=()

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

_pkg_install() {
  [ $# -gt 0 ] || {
    printf 'pkg: install requires at least one package\n' >&2
    return 2
  }

  local name
  local -a natives=()

  for name in "$@"; do
    natives+=("$(_pkg_native_name "$name")")
  done

  _pkg_run pacman -S --needed --noconfirm -- "${natives[@]}"
}

_pkg_remove() {
  [ $# -gt 0 ] || {
    printf 'pkg: remove requires at least one package\n' >&2
    return 2
  }

  local name
  local -a natives=()

  for name in "$@"; do
    natives+=("$(_pkg_native_name "$name")")
  done

  _pkg_run pacman -Rns --noconfirm -- "${natives[@]}"
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
      if pacman -Qg base-devel >/dev/null 2>&1; then
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
