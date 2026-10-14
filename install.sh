#!/usr/bin/env bash
# Installs the tools this config needs, at pinned versions, then installs plugins, parsers and language servers.
# Binaries come from GitHub releases, so PyPI mirrors and uv "exclude-newer" settings have no effect.
# The script is safe to run again. It skips each tool that is already at the pinned version.
#
# Usage: ./install.sh [--skip-nvim-setup]
# Set BIN_DIR to change the install folder (default: ~/.local/bin). Neovim goes to $OPT_DIR (default: ~/.local/opt).
set -euo pipefail

NVIM_VERSION=0.12.6
TREE_SITTER_VERSION=0.27.1
TY_VERSION=0.0.86
RUFF_VERSION=0.17.0

BIN_DIR=${BIN_DIR:-$HOME/.local/bin}
OPT_DIR=${OPT_DIR:-$HOME/.local/opt}
CONFIG_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKIP_NVIM_SETUP=0
[ "${1:-}" = "--skip-nvim-setup" ] && SKIP_NVIM_SETUP=1

case "$(uname -m)" in
  x86_64) ARCH=x86_64; TS_ARCH=x64 ;;
  aarch64 | arm64) ARCH=aarch64; TS_ARCH=arm64 ;;
  *) echo "Unsupported CPU architecture: $(uname -m)" >&2; exit 1 ;;
esac
[ "$(uname -s)" = "Linux" ] || { echo "This script supports Linux only." >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$BIN_DIR" "$OPT_DIR"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }

# Prints the version that "<cmd> --version" reports, or nothing if the command is missing.
installed_version() {
  [ -x "$BIN_DIR/$1" ] || return 0
  "$BIN_DIR/$1" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true
}

# Replaces the file instead of writing through it. ~/.local/bin/ty can be a symlink into a uv tool environment.
put_bin() {
  rm -f "$BIN_DIR/$2"
  install -m 755 "$1" "$BIN_DIR/$2"
}

# 1. System tools. The script does not use sudo. It only reports what is missing.
missing=()
for cmd in git curl tar gzip make cc rg; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
  warn "Missing system tools: ${missing[*]}"
  warn "On Ubuntu/Debian: sudo apt install git curl make build-essential ripgrep fd-find"
  if printf '%s\n' "${missing[@]}" | grep -qE '^(curl|tar|gzip)$'; then
    echo "curl, tar and gzip are required for the downloads below." >&2
    exit 1
  fi
fi

# 2. Neovim
if [ "$(installed_version nvim)" = "$NVIM_VERSION" ]; then
  log "Neovim $NVIM_VERSION is already installed"
else
  log "Installing Neovim $NVIM_VERSION"
  NVIM_ASSET=nvim-linux-$( [ "$ARCH" = x86_64 ] && echo x86_64 || echo arm64 )
  curl -fsSL "https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/$NVIM_ASSET.tar.gz" | tar -xz -C "$WORK"
  rm -rf "${OPT_DIR:?}/$NVIM_ASSET"
  mv "$WORK/$NVIM_ASSET" "$OPT_DIR/"
  rm -f "$BIN_DIR/nvim"
  ln -s "$OPT_DIR/$NVIM_ASSET/bin/nvim" "$BIN_DIR/nvim"
fi

# 3. tree-sitter CLI. nvim-treesitter uses it to compile parsers.
if [ "$(installed_version tree-sitter)" = "$TREE_SITTER_VERSION" ]; then
  log "tree-sitter $TREE_SITTER_VERSION is already installed"
else
  log "Installing tree-sitter $TREE_SITTER_VERSION"
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-linux-$TS_ARCH.gz" \
    | gunzip > "$WORK/tree-sitter"
  put_bin "$WORK/tree-sitter" tree-sitter
fi

# 4. ty and ruff, the Python language servers. ty must be 0.0.85 or newer for auto-import from namespace packages.
install_astral() { # install_astral NAME VERSION
  if [ "$(installed_version "$1")" = "$2" ]; then
    log "$1 $2 is already installed"
    return
  fi
  log "Installing $1 $2"
  local asset="$1-$ARCH-unknown-linux-gnu"
  curl -fsSL "https://github.com/astral-sh/$1/releases/download/$2/$asset.tar.gz" | tar -xz -C "$WORK"
  put_bin "$WORK/$asset/$1" "$1"
  if command -v uv >/dev/null && uv tool list 2>/dev/null | grep -q "^$1 "; then
    warn "uv also manages a copy of $1. Run 'uv tool uninstall $1' to stop it from replacing this one."
  fi
}
install_astral ty "$TY_VERSION"
install_astral ruff "$RUFF_VERSION"

# Neovim and its language servers find these tools through PATH.
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not in PATH. Add this line to your shell startup file: export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
export PATH="$BIN_DIR:$PATH"
hash -r

# 5. Plugins, parsers and Mason servers. The steps run in headless Neovim with this config.
if [ "$SKIP_NVIM_SETUP" = 1 ]; then
  log "Skipping Neovim setup (--skip-nvim-setup)"
else
  if [ "$CONFIG_DIR" != "$(cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" 2>/dev/null && pwd)" ]; then
    warn "This script is not in ~/.config/nvim. Neovim will load the config from ~/.config/nvim, not from $CONFIG_DIR."
  fi

  log "Installing plugins at the versions in lazy-lock.json"
  nvim --headless "+Lazy! restore" +qa

  log "Compiling Tree-sitter parsers"
  nvim --headless -c "lua require('nvim-treesitter').install({ 'python', 'lua', 'c', 'cpp', 'vim', 'vimdoc', 'markdown', 'markdown_inline' }):wait(300000)" -c qa

  log "Installing lua-language-server and clangd with Mason"
  if ! timeout 600 nvim --headless "+MasonInstall lua-language-server clangd" +qa; then
    warn "Mason did not finish. Open Neovim and run :MasonInstall lua-language-server clangd"
  fi
fi

log "Installed versions:"
for cmd in nvim tree-sitter ty ruff; do
  printf '  %-12s %s\n' "$cmd" "$(installed_version "$cmd")"
done
