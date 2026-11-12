# shellcheck shell=bash
# Ubuntu/Debian backend for the dotfiles pkg dispatcher.

declare -gA PKG_MAP=(
  [build-essential]=build-essential
  [fd]=fd-find
)

declare -gA PKG_METHOD=(
  [starship]=github
  [mise]=installer
)

STARSHIP_VERSION=v1.27.0
MISE_VERSION=v2026.11.7

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

_pkg_install_github() {
  local name=$1 version asset base tmp checksum

  case $name in
    starship)
      version=$STARSHIP_VERSION
      case $(uname -m) in
        x86_64 | amd64)
          asset=starship-x86_64-unknown-linux-gnu.tar.gz
          ;;
        aarch64 | arm64)
          asset=starship-aarch64-unknown-linux-musl.tar.gz
          ;;
        *)
          printf 'pkg: starship: unsupported architecture: %s\n' "$(uname -m)" >&2
          return 1
          ;;
      esac
      base=https://github.com/starship/starship/releases/download/$version
      ;;
    *)
      printf 'pkg: no GitHub installer for %s\n' "$name" >&2
      return 1
      ;;
  esac

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: install %s %s from %s/%s (sha256 verified) into %s\n' \
      "$name" "$version" "$base" "$asset" "$HOME/.local/bin/$name"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! curl -fsSL -o "$tmp/$asset" "$base/$asset" ||
    ! curl -fsSL -o "$tmp/$asset.sha256" "$base/$asset.sha256"; then
    rm -rf "$tmp"
    return 1
  fi

  checksum=$(cat "$tmp/$asset.sha256") || {
    rm -rf "$tmp"
    return 1
  }
  if ! (cd "$tmp" && printf '%s  %s\n' "$checksum" "$asset" | sha256sum -c -); then
    rm -rf "$tmp"
    return 1
  fi

  mkdir -p "$HOME/.local/bin" || {
    rm -rf "$tmp"
    return 1
  }
  if ! tar -xzf "$tmp/$asset" -C "$tmp" ||
    ! install -m 0755 "$tmp/$name" "$HOME/.local/bin/$name"; then
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$tmp"
}

_pkg_install_installer() {
  local name=$1

  case $name in
    mise)
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: install mise %s via https://mise.run into %s\n' \
          "$MISE_VERSION" "$HOME/.local/bin/mise"
        return 0
      fi
      mkdir -p "$HOME/.local/bin" || return 1
      curl -fsSL https://mise.run |
        MISE_VERSION="$MISE_VERSION" MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
      ;;
    *)
      printf 'pkg: no standalone installer for %s\n' "$name" >&2
      return 1
      ;;
  esac
}

_pkg_link_fd() {
  local source

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    source=$(command -v fdfind || printf '/usr/bin/fdfind')
    printf 'DRY: ln -sfn %q %q\n' "$source" "$HOME/.local/bin/fd"
    return 0
  fi

  source=$(command -v fdfind || true)
  [ -n "$source" ] || return 0

  mkdir -p "$HOME/.local/bin" || return 1
  ln -sfn "$source" "$HOME/.local/bin/fd"
}

_pkg_remove_special() {
  local name=$1

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: rm -f %q\n' "$HOME/.local/bin/$name"
    return 0
  fi

  rm -f "$HOME/.local/bin/$name"
}

_pkg_install() {
  [ $# -gt 0 ] || {
    printf 'pkg: install requires at least one package\n' >&2
    return 2
  }

  local name native
  local fd_requested=0
  local -a natives=()
  local -a specials=()

  for name in "$@"; do
    case ${PKG_METHOD[$name]:-} in
      github | installer)
        specials+=("$name")
        ;;
      *)
        native=$(_pkg_native_name "$name")
        natives+=("$native")
        [ "$name" = fd ] && fd_requested=1
        ;;
    esac
  done

  if [ ${#natives[@]} -gt 0 ]; then
    _pkg_run apt-get install -y -- "${natives[@]}" || return
  fi

  for name in "${specials[@]}"; do
    case ${PKG_METHOD[$name]} in
      github)
        _pkg_install_github "$name" || return
        ;;
      installer)
        _pkg_install_installer "$name" || return
        ;;
    esac
  done

  if [ "$fd_requested" = 1 ]; then
    _pkg_link_fd
  fi
}

_pkg_remove() {
  [ $# -gt 0 ] || {
    printf 'pkg: remove requires at least one package\n' >&2
    return 2
  }

  local name
  local fd_requested=0
  local -a natives=()
  local -a specials=()

  for name in "$@"; do
    case ${PKG_METHOD[$name]:-} in
      github | installer)
        specials+=("$name")
        ;;
      *)
        natives+=("$(_pkg_native_name "$name")")
        [ "$name" = fd ] && fd_requested=1
        ;;
    esac
  done

  if [ ${#natives[@]} -gt 0 ]; then
    _pkg_run apt-get remove -y -- "${natives[@]}" || return
  fi

  for name in "${specials[@]}"; do
    _pkg_remove_special "$name" || return
  done

  if [ "$fd_requested" = 1 ]; then
    _pkg_remove_special fd
  fi
}

_pkg_update() {
  _pkg_run apt-get update
}

_pkg_upgrade() {
  _pkg_run apt-get update || return
  _pkg_run apt-get upgrade -y
}

_pkg_search() {
  _pkg_run_plain apt-cache search -- "$@"
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
    if [ -n "${PKG_METHOD[$name]:-}" ]; then
      if command -v "$name" >/dev/null 2>&1 ||
        [ -x "$HOME/.local/bin/$name" ]; then
        printf '%s: installed\n' "$name"
      else
        printf '%s: missing\n' "$name"
        rc=1
      fi
      continue
    fi

    native=$(_pkg_native_name "$name")
    if dpkg-query -W -f='${Status}' "$native" 2>/dev/null |
      grep -q 'install ok installed'; then
      printf '%s: installed\n' "$name"
    else
      printf '%s: missing\n' "$name"
      rc=1
    fi
  done

  return "$rc"
}
