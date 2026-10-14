# Neovim config

A small, modular Neovim config using [lazy.nvim](https://github.com/folke/lazy.nvim),
Telescope + fzf for VS Code–style file finding and searching, a file tree sidebar,
Tree-sitter highlighting, LSP code navigation and auto-import (Python, C/C++, Lua), and the
Gruvbox colorscheme (hard contrast, deuteranomaly-friendly).

## Install

```sh
# Back up any existing config first
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

git clone https://github.com/gonzalogacc/nvim-config.git ~/.config/nvim
~/.config/nvim/install.sh
```

`install.sh` installs everything at pinned versions:

| Tool | Version | Used for |
|---|---|---|
| Neovim | 0.12.6 | The editor. This config needs 0.12 or newer. |
| tree-sitter CLI | 0.27.1 | Compiling syntax parsers (needs 0.26.1 or newer) |
| ty | 0.0.86 | Python types, missing-import errors, auto-import (needs 0.0.85 or newer) |
| ruff | 0.17.0 | Python lint and import sorting |

It then runs Neovim headless to install the plugins from `lazy-lock.json`, compile the
Tree-sitter parsers, and install `lua-language-server` and `clangd` with Mason.

Notes:

- The tools go to `~/.local/bin`, and Neovim to `~/.local/opt`. Make sure `~/.local/bin`
  comes first in your `PATH`. Set `BIN_DIR` or `OPT_DIR` to change the folders.
- The binaries come from GitHub releases, not PyPI. A company PyPI mirror or a uv
  `exclude-newer` setting can serve old versions. For example, ty 0.0.84 gives no
  auto-import suggestions for code in namespace packages.
- If uv also manages `ty` or `ruff` (`uv tool list`), remove that copy with
  `uv tool uninstall ty ruff`. Otherwise a later uv command can replace the newer binary.
- The script does not use `sudo`. It lists missing system tools. On Ubuntu/Debian:

  ```sh
  sudo apt install git curl make build-essential ripgrep fd-find
  ```

- Run the script again at any time. It skips tools that are already at the pinned version.
  To update a tool, change its version at the top of `install.sh`.
- `./install.sh --skip-nvim-setup` installs only the binaries.

### Python projects (uv)

ty finds the project's `.venv` by itself. Run `uv sync` in the project first, so the
packages exist in `.venv`. Then open Neovim from the project folder:

- Missing imports get an error underline.
- `Space .` on an undefined name lists the possible imports.
- In insert mode, completion entries marked `(import ...)` add the import when you accept them.

To check that the language servers run, open a `.py` file and run `:checkhealth vim.lsp`.
Both `ty` and `ruff` must be listed as attached.

### Update plugins

`lazy-lock.json` pins plugin versions so every machine gets the same ones.
Run `:Lazy sync` to update plugins and the lockfile.

## Layout

```
install.sh                  installs Neovim, tree-sitter, ty, ruff, plugins and parsers
init.lua                    leader key + loads the modules below
lua/config/options.lua      editor options (indent, splits, search)
lua/config/keymaps.lua      general keymaps (splits, window movement, search)
lua/config/lazy.lua         bootstraps lazy.nvim, loads lua/plugins/*
lua/plugins/colorscheme.lua Gruvbox theme (hard contrast, accessible diagnostics)
lua/plugins/lsp.lua         LSP setup (ty + ruff for Python, clangd, lua_ls), completion, Mason
lua/plugins/git.lua         git gutter: diff with main (mini.diff), uncommitted changes (gitsigns)
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
| `Space [` / `Space ]` | Jump back / forward, like browser back and forward |
| `Ctrl+o` / `Ctrl+i` | Jump back / forward (Vim default) |
| `Space .` | Import symbol / quick fix menu (like VS Code Cmd+.) |
| `Space ca` | Code action menu |
| `Space rn` | Rename symbol across project |
| `[d` / `]d` | Previous / next diagnostic error or warning |
| `Space cd` | Show diagnostics float for current line |
| `Tab` / `Enter` | Accept completion in insert mode (adds the import if needed) |
| `Ctrl+n` / `Ctrl+p` | Next / previous completion item |
| `Ctrl+Space` | Open completion menu |


### Git changes

The gutter shows two git columns, next to the line numbers:

| Marker | Meaning |
|---|---|
| `│` thin bar, right column | Line differs from `main` (committed on this branch or not) |
| `┃` thick bar, left column | Changed, not staged |
| `┋` dotted bar, left column | Staged (`git add`), not committed |
| `┆` | Untracked file |
| `▁` / `_` | Lines were deleted below this line |

So a line with only `│` is committed on the branch. A line with `┃` or `┋` too has edits that are not committed yet.
The branch column compares with the merge-base of `HEAD` and `main` (or `master`, `origin/main`, `origin/master`).

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous change compared with main |
| `]c` / `[c` | Next / previous uncommitted change |
| `Space gd` | Show the diff with main inline (toggle) |
| `Space gp` | Preview the uncommitted change under the cursor |
| `Space gs` | Stage the change under the cursor |
| `Space gr` | Discard the uncommitted change under the cursor |
| `Space gb` | Show who last changed the line (blame) |

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
| `Space h` / `Space l` | Jump between the tree and the file |

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
| `Space h` / `Space l` | Move to window left / right |
| `Ctrl+j` / `Ctrl+k` | Move to window down / up |
| `Ctrl+arrow keys` | Resize the current window |
| `Space =` | Make all splits the same size |

New splits open on the right and below.

## tmux

For `Ctrl+Shift+F` to reach Neovim inside tmux, add this to `~/.tmux.conf`:

```tmux
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
```
