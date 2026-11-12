# shellcheck shell=bash

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

_source_dir "$HOME/.profile.d"
export __DOTFILES_PROFILE_D_LOADED=1

if [ -f "$HOME/.bashrc" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$HOME/.bashrc"
fi

unset -f _source_dir
