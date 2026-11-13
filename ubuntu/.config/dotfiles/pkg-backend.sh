# shellcheck shell=bash
# Ubuntu/Debian backend for the dotfiles pkg dispatcher.

declare -gA PKG_MAP=(
  [build-essential]=build-essential
  [fd]=fd-find
)

declare -gA PKG_METHOD=(
  [starship]=github
  [mise]=installer
  [nix]=installer
  [opencode]=github
  [neovim]=github
  [kubectl]=installer
)

STARSHIP_VERSION=v1.27.0
MISE_VERSION=v2026.11.7
NIX_VERSION=2.35.1
OPENCODE_VERSION=v1.19.5
NEOVIM_VERSION=v0.12.6
KUBECTL_VERSION=v1.37.2

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
  local name=$1 version asset base tmp checksum target neovim_dir opt_dir

  case $name in
    neovim)
      version=$NEOVIM_VERSION
      case $(uname -m) in
        x86_64 | amd64)
          asset=nvim-linux-x86_64.tar.gz
          neovim_dir=nvim-linux-x86_64
          checksum=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
          ;;
        aarch64 | arm64)
          asset=nvim-linux-arm64.tar.gz
          neovim_dir=nvim-linux-arm64
          checksum=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815
          ;;
        *)
          printf 'pkg: neovim: unsupported architecture: %s\n' "$(uname -m)" >&2
          return 1
          ;;
      esac
      base=https://github.com/neovim/neovim/releases/download/$version
      target=$HOME/.local/bin/nvim
      ;;
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
    opencode)
      version=$OPENCODE_VERSION
      case $(uname -m) in
        x86_64 | amd64)
          asset=opencode-linux-x64.tar.gz
          checksum=588310a336fa3b9df36b3f0225b26f679d453efaad0cf3d66c3651ef3ec1647a
          ;;
        aarch64 | arm64)
          asset=opencode-linux-arm64.tar.gz
          checksum=fae5be262d693b7c5e562856cc473e59e741772936db0c0600ac0d5ed5bd088b
          ;;
        *)
          printf 'pkg: opencode: unsupported architecture: %s\n' "$(uname -m)" >&2
          return 1
          ;;
      esac
      base=https://github.com/anomalyco/opencode/releases/download/$version
      ;;
    *)
      printf 'pkg: no GitHub installer for %s\n' "$name" >&2
      return 1
      ;;
  esac

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    printf 'DRY: install %s %s from %s/%s (sha256 verified) into %s\n' \
      "$name" "$version" "$base" "$asset" "${target:-$HOME/.local/bin/$name}"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! curl -fsSL -o "$tmp/$asset" "$base/$asset"; then
    rm -rf "$tmp"
    return 1
  fi

  if [ -z "$checksum" ]; then
    if ! curl -fsSL -o "$tmp/$asset.sha256" "$base/$asset.sha256"; then
      rm -rf "$tmp"
      return 1
    fi
    checksum=$(cat "$tmp/$asset.sha256") || {
      rm -rf "$tmp"
      return 1
    }
  fi

  if ! (cd "$tmp" && printf '%s  %s\n' "$checksum" "$asset" | sha256sum -c -); then
    rm -rf "$tmp"
    return 1
  fi

  mkdir -p "$HOME/.local/bin" || {
    rm -rf "$tmp"
    return 1
  }
  if [ -n "$neovim_dir" ]; then
    opt_dir=$HOME/.local/opt/nvim-${version#v}
    mkdir -p "$HOME/.local/opt" || {
      rm -rf "$tmp"
      return 1
    }
    if ! tar -xzf "$tmp/$asset" -C "$tmp"; then
      rm -rf "$tmp"
      return 1
    fi
    rm -rf "$opt_dir"
    if ! mv "$tmp/$neovim_dir" "$opt_dir" ||
      ! ln -sfn "$opt_dir/bin/nvim" "$target"; then
      rm -rf "$tmp"
      return 1
    fi
    rm -rf "$tmp"
    return 0
  fi
  if ! tar -xzf "$tmp/$asset" -C "$tmp" ||
    ! install -m 0755 "$tmp/$name" "$HOME/.local/bin/$name"; then
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$tmp"
}

_pkg_install_installer() {
  local name=$1 arch checksum tmp

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
    nix)
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: install nix %s single-user (no-daemon, no profile edits)\n' "$NIX_VERSION"
        return 0
      fi
      curl -fsSL "https://releases.nixos.org/nix/nix-$NIX_VERSION/install" |
        sh -s -- --no-daemon --no-modify-profile
      ;;
    kubectl)
      case $(uname -m) in
        x86_64 | amd64)
          arch=amd64
          checksum=c04487523e7aa7d1493f7808174c899db93d7a9cf57531420cd76b9bd415f8f4
          ;;
        aarch64 | arm64)
          arch=arm64
          checksum=fcc16f63186659d9722014b7e02d5fdd2d4e669cb8c0ab66365d7d3b8ba03509
          ;;
        *)
          printf 'pkg: kubectl: unsupported architecture: %s\n' "$(uname -m)" >&2
          return 1
          ;;
      esac
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: install kubectl %s (%s) from dl.k8s.io into %s\n' \
          "$KUBECTL_VERSION" "$arch" "$HOME/.local/bin/kubectl"
        return 0
      fi
      tmp=$(mktemp -d) || return 1
      if ! curl -fsSL -o "$tmp/kubectl" \
        "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$arch/kubectl"; then
        rm -rf "$tmp"
        return 1
      fi
      if ! (cd "$tmp" && printf '%s  kubectl\n' "$checksum" | sha256sum -c -); then
        rm -rf "$tmp"
        return 1
      fi
      mkdir -p "$HOME/.local/bin" || {
        rm -rf "$tmp"
        return 1
      }
      if ! install -m 0755 "$tmp/kubectl" "$HOME/.local/bin/kubectl"; then
        rm -rf "$tmp"
        return 1
      fi
      rm -rf "$tmp"
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

_pkg_link_bat() {
  local source

  if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
    source=$(command -v batcat || printf '/usr/bin/batcat')
    printf 'DRY: ln -sfn %q %q\n' "$source" "$HOME/.local/bin/bat"
    return 0
  fi

  source=$(command -v batcat || true)
  [ -n "$source" ] || return 0

  mkdir -p "$HOME/.local/bin" || return 1
  ln -sfn "$source" "$HOME/.local/bin/bat"
}

_pkg_remove_special() {
  local name=$1

  case $name in
    nix)
      local -a nix_paths=(
        "$HOME/.nix-profile"
        "$HOME/.nix-defexpr"
        "$HOME/.nix-channels"
        "$HOME/.local/state/nix"
        "$HOME/.cache/nix"
      )
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: sudo rm -rf /nix; rm -rf'
        printf ' %q' "${nix_paths[@]}"
        printf '\n'
        return 0
      fi
      if [ -e /nix ] || [ -L /nix ]; then
        _pkg_sudo rm -rf -- /nix || return
      fi
      rm -rf "${nix_paths[@]}"
      ;;
    neovim)
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: rm -f %q; rm -rf %q\n' \
          "$HOME/.local/bin/nvim" "$HOME/.local/opt/nvim-*"
        return 0
      fi
      rm -f "$HOME/.local/bin/nvim"
      rm -rf "$HOME/.local/opt"/nvim-*
      ;;
    kubectl)
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: rm -f %q\n' "$HOME/.local/bin/kubectl"
        return 0
      fi
      rm -f "$HOME/.local/bin/kubectl"
      ;;
    *)
      if [ "${PKG_DRY_RUN:-0}" = 1 ]; then
        printf 'DRY: rm -f %q\n' "$HOME/.local/bin/$name"
        return 0
      fi
      rm -f "$HOME/.local/bin/$name"
      ;;
  esac
}

_pkg_install() {
  [ $# -gt 0 ] || {
    printf 'pkg: install requires at least one package\n' >&2
    return 2
  }

  local name native
  local fd_requested=0
  local bat_requested=0
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
        [ "$name" = bat ] && bat_requested=1
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

  if [ "$bat_requested" = 1 ]; then
    _pkg_link_bat
  fi
}

_pkg_remove() {
  [ $# -gt 0 ] || {
    printf 'pkg: remove requires at least one package\n' >&2
    return 2
  }

  local name
  local fd_requested=0
  local bat_requested=0
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
        [ "$name" = bat ] && bat_requested=1
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

  if [ "$bat_requested" = 1 ]; then
    _pkg_remove_special bat
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
    if [ "$name" = nix ]; then
      if [ -x "$HOME/.nix-profile/bin/nix" ]; then
        printf '%s: installed\n' "$name"
      else
        printf '%s: missing\n' "$name"
        rc=1
      fi
      continue
    fi

    if [ "$name" = neovim ]; then
      if command -v nvim >/dev/null 2>&1 ||
        [ -x "$HOME/.local/bin/nvim" ]; then
        printf '%s: installed\n' "$name"
      else
        printf '%s: missing\n' "$name"
        rc=1
      fi
      continue
    fi

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
