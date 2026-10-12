# Neovim config

A small, modular Neovim config using [lazy.nvim](https://github.com/folke/lazy.nvim),
Telescope + fzf for VS Code–style file finding and searching, a file tree sidebar,
Tree-sitter highlighting, LSP code navigation (Python, C/C++, Lua), and the
Gruvbox colorscheme (hard contrast, deuteranomaly-friendly).

## Requirements

- Neovim 0.11+ (tested on 0.12)
- `git`, `make`, `gcc` (to build telescope-fzf-native and treesitter parsers)
- [ripgrep](https://github.com/BurntSushi/ripgrep) for searching text across files
- `node` & `npm` (for language servers like Pyright)
- Optional: `fd` for faster file finding

On Ubuntu/Debian:

```sh
sudo apt install git make gcc ripgrep fd-find
```

## Install

```sh
# Back up any existing config first
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

git clone https://github.com/gonzalogacc/nvim-config.git ~/.config/nvim
nvim
```

The first launch installs lazy.nvim and all plugins automatically.
`lazy-lock.json` pins plugin versions so every machine gets the same ones.
Run `:Lazy sync` to update plugins.

## Layout

```
init.lua                    leader key + loads the modules below
lua/config/options.lua      editor options (indent, splits, search)
lua/config/keymaps.lua      general keymaps (splits, window movement, search)
lua/config/lazy.lua         bootstraps lazy.nvim, loads lua/plugins/*
lua/plugins/colorscheme.lua Gruvbox theme (hard contrast, accessible diagnostics)
lua/plugins/lsp.lua         LSP setup (Pyright, Clangd, Lua) + Mason
lua/plugins/telescope.lua   Telescope + fzf-native and its keymaps
lua/plugins/nvim-tree.lua   file tree sidebar
lua/plugins/treesitter.lua  Tree-sitter highlighting/indent for Python, C/C++, Lua, etc.
```

To add a plugin, create a new file in `lua/plugins/` that returns a lazy.nvim spec.

## Shortcuts

The leader key is **Space**. Press `Space fk` inside Neovim to search all keymaps.
For a short printable version, see [`cheatsheet.txt`](cheatsheet.txt).

### Find files & search

| Key | Action |
|---|---|
| `Ctrl+P` / `Space ff` | Find files |
| `Ctrl+Shift+F` / `Space fg` | Search text across all files |
| `Space Space` | Switch between open files |
| `Space /` | Fuzzy search in the current file |
| `Space fw` | Search the word under the cursor across files |
| `Space f.` | Reopen the last search |
| `Space fr` | Recent files |
| `Space fb` | Open buffers |
| `Space fd` | Diagnostics (errors and warnings) |
| `Space fk` | Search keymaps |
| `Space fh` | Help |

`Cmd+P` / `Cmd+Shift+F` (Super key) are also mapped, but only work in a GUI like
Neovide or a terminal that forwards the Super key. Inside tmux, `Ctrl+Shift+F`
needs extended keys enabled (see [tmux](#tmux)).

### Inside Telescope

| Key | Action |
|---|---|
| `Ctrl+n` / `Ctrl+p` | Move down or up through results |
| `Enter` | Open |
| `Ctrl+v` / `Ctrl+x` | Open in a side / bottom split |
| `Ctrl+q` | Send all results to the quickfix list |
| `Esc` | Close |

### Code navigation (LSP)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Find references (opens Telescope) |
| `gy` | Go to type definition |
| `K` | Hover documentation / signatures |
| `Ctrl+k` | Signature help |
| `Ctrl+o` / `Ctrl+i` | Jump backward / forward in jump list |
| `Space .` | Import symbol / quick fix menu (like VS Code Cmd+.) |
| `Space ca` | Code action menu |
| `Space rn` | Rename symbol across project |
| `[d` / `]d` | Previous / next diagnostic error or warning |
| `Space cd` | Show diagnostics float for current line |
| `Tab` / `Enter` | Accept completion in insert mode (adds the import if needed) |
| `Ctrl+n` / `Ctrl+p` | Next / previous completion item |
| `Ctrl+Space` | Open completion menu |


### Search within a file

| Key | Action |
|---|---|
| `/text` | Search forward |
| `n` / `N` | Next / previous match (centered on screen) |
| `Esc` | Clear search highlighting |

Searches ignore case unless you type a capital letter.

### File tree

Run `nvim`, `nvim .` or `nvim some/dir` to open with the tree on the left. The tree
follows and highlights the file you're editing.

| Key | Action |
|---|---|
| `Space e` | Show / hide the tree |
| `Space E` | Reveal the current file in the tree |
| `Ctrl+h` / `Ctrl+l` | Jump between the tree and the file |

Inside the tree:

| Key | Action |
|---|---|
| `Enter` | Open file / expand folder |
| `Ctrl+v` / `Ctrl+x` | Open in a side / bottom split |
| `a` | New file (end the name with `/` for a folder) |
| `r` | Rename |
| `d` | Delete |
| `x` / `c` / `p` | Cut / copy / paste |
| `H` | Show / hide dotfiles |
| `R` | Refresh |
| `g?` | Show all tree keys |

### Splits & windows

| Key | Action |
|---|---|
| `Space v` | Split left/right |
| `Space s` | Split top/bottom |
| `Space q` | Close the current window |
| `Ctrl+h/j/k/l` | Move to the window left/down/up/right |
| `Ctrl+arrow keys` | Resize the current window |
| `Space =` | Make all splits the same size |

New splits open on the right and below.

## tmux

For `Ctrl+Shift+F` to reach Neovim inside tmux, add this to `~/.tmux.conf`:

```tmux
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
```
