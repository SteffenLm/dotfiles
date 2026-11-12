# shellcheck shell=bash

case $- in
  *i*) ;;
  *) return ;;
esac

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin${PATH:+:$PATH}" ;;
esac
export PATH

_source_dir() {
  local dir=$1 file
  [ -d "$dir" ] || return 0
  while IFS= read -r -d '' file; do
    # shellcheck disable=SC1090,SC1091
    . "$file"
  done < <(find -L "$dir" -type f -print0 2>/dev/null | LC_ALL=C sort -z)
}

if [ -z "${__DOTFILES_PROFILE_D_LOADED:-}" ]; then
  _source_dir "$HOME/.profile.d"
  export __DOTFILES_PROFILE_D_LOADED=1
fi

_source_dir "$HOME/.bashrc.d"
_source_dir "$HOME/.alias.d"

unset -f _source_dir
