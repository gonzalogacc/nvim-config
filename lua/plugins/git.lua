-- Two git gutters:
--   mini.diff: every line that differs from the main branch (commits on this branch and uncommitted edits).
--   gitsigns:  only changes that are not committed yet. Staged and unstaged changes use different symbols.

-- Branches to compare with, in order. The first one that exists is used.
local BASE_BRANCHES = { "main", "master", "origin/main", "origin/master" }

local function git(dir, args)
  local res = vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
  if res.code ~= 0 then return nil end
  return res.stdout
end

-- Returns the repo root and the merge-base of HEAD and the main branch, or nil.
-- nil means: not in a git repo, or no main branch.
local function merge_base(dir)
  local root = git(dir, { "rev-parse", "--show-toplevel" })
  if not root then return nil end
  for _, branch in ipairs(BASE_BRANCHES) do
    local base = git(dir, { "merge-base", "HEAD", branch })
    if base then return vim.trim(root), vim.trim(base) end
  end
  return nil
end

-- Returns the file content at the merge-base of HEAD and the main branch, or nil.
-- nil means: not in a git repo, no main branch, or the file is outside the repo.
local function main_branch_text(path)
  local root, base = merge_base(vim.fs.dirname(path))
  if not root then return nil end
  local rel = vim.fs.relpath(root, path)
  if not rel then return nil end
  -- A file that is new on this branch has no content at the base, so every line shows as added.
  return git(root, { "show", base .. ":" .. rel }) or ""
end

-- Returns the repo root, the merge-base, and the paths that differ from it, or nil with a message.
-- The paths include uncommitted edits and untracked files. Paths are relative to the root.
local function branch_changes()
  local root, base = merge_base(vim.fn.getcwd())
  if not root then return nil, "No git repo or no main branch" end
  local files, seen = {}, {}
  local tracked = git(root, { "diff", "--name-only", base }) or ""
  local untracked = git(root, { "ls-files", "--others", "--exclude-standard" }) or ""
  for f in (tracked .. untracked):gmatch("[^\n]+") do
    if not seen[f] then
      seen[f] = true
      files[#files + 1] = f
    end
  end
  return root, base, files
end

-- Telescope picker of the files that differ from the main branch. The preview shows the diff of each file.
local function pick_changed_files()
  local root, base, files = branch_changes()
  if not root then return vim.notify(base, vim.log.levels.WARN) end
  if #files == 0 then return vim.notify("No changes vs main", vim.log.levels.INFO) end
  local conf = require("telescope.config").values
  require("telescope.pickers").new({}, {
    prompt_title = "Changed vs main",
    cwd = root,
    finder = require("telescope.finders").new_table({
      results = files,
      entry_maker = function(f)
        return { value = f, display = f, ordinal = f, path = root .. "/" .. f }
      end,
    }),
    sorter = conf.file_sorter({}),
    previewer = require("telescope.previewers").new_buffer_previewer({
      title = "Diff vs main",
      define_preview = function(self, entry)
        local out = git(root, { "diff", base, "--", entry.value }) or ""
        -- Untracked files have no diff. Show the whole file instead.
        if out == "" then
          local ok, lines = pcall(vim.fn.readfile, entry.path)
          out = ok and table.concat(lines, "\n") or ""
        else
          vim.bo[self.state.bufnr].filetype = "diff"
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(out, "\n"))
      end,
    }),
  }):find()
end

-- Fills the quickfix list with one entry per hunk that differs from the main branch, then opens it.
-- Untracked files get one entry at line 1.
local function branch_hunks_to_qf()
  local root, base, files = branch_changes()
  if not root then return vim.notify(base, vim.log.levels.WARN) end
  local items, file = {}, nil
  -- -U0 removes context lines, so each @@ header marks exactly one hunk.
  for line in (git(root, { "diff", "-U0", "--no-color", base }) or ""):gmatch("[^\n]+") do
    local path = line:match("^%+%+%+ b/(.+)$")
    if path then
      file = path
    elseif line:match("^%+%+%+ /dev/null") then
      file = nil -- Deleted file: there is no line to jump to.
    elseif file then
      local start, count = line:match("^@@ %-[%d,]+ %+(%d+),?(%d*) @@")
      if start then
        local added = count == "" and 1 or tonumber(count)
        -- A pure deletion reports the line before the gap. Line 0 means the top of the file.
        items[#items + 1] = {
          filename = root .. "/" .. file,
          lnum = math.max(tonumber(start), 1),
          text = added == 0 and "deleted lines" or (added .. " line(s) changed"),
        }
      end
    end
  end
  local tracked = {}
  for f in (git(root, { "diff", "--name-only", base }) or ""):gmatch("[^\n]+") do tracked[f] = true end
  for _, f in ipairs(files) do
    if not tracked[f] then
      items[#items + 1] = { filename = root .. "/" .. f, lnum = 1, text = "new untracked file" }
    end
  end
  if #items == 0 then return vim.notify("No changes vs main", vim.log.levels.INFO) end
  vim.fn.setqflist({}, " ", { title = "Changes vs main", items = items })
  vim.cmd("copen")
end

local function main_branch_source()
  local group = vim.api.nvim_create_augroup("UserMiniDiffMain", { clear = true })
  local function refresh(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" or vim.bo[buf].buftype ~= "" then return end
    local text = main_branch_text(path)
    if text then
      require("mini.diff").set_ref_text(buf, text)
    else
      require("mini.diff").set_ref_text(buf, {})
    end
  end
  return {
    name = "main-branch",
    attach = function(buf)
      local path = vim.api.nvim_buf_get_name(buf)
      if path == "" or vim.bo[buf].buftype ~= "" then return false end
      -- No main branch or no repo: show nothing instead of marking every line as added.
      if not main_branch_text(path) then return false end
      refresh(buf)
      -- A commit, checkout or rebase moves HEAD and so the merge-base. Recompute on these events.
      vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
        group = group,
        buffer = buf,
        callback = function() refresh(buf) end,
      })
    end,
    detach = function(buf)
      pcall(vim.api.nvim_clear_autocmds, { group = group, buffer = buf })
    end,
  }
end

return {
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    opts = {
      -- Unstaged changes: thick bar.
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "┃" },
        untracked = { text = "┆" },
      },
      -- Staged changes (git add) that are not committed: dotted bar.
      signs_staged = {
        add = { text = "┋" },
        change = { text = "┋" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "┋" },
      },
      attach_to_untracked = true,
      -- Higher than mini.diff and lower than diagnostics (10). Gutter order, left to right: diagnostics, uncommitted, branch.
      sign_priority = 8,
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = "Git: " .. desc })
        end
        map("]c", function() gs.nav_hunk("next") end, "Next uncommitted change")
        map("[c", function() gs.nav_hunk("prev") end, "Previous uncommitted change")
        map("<leader>gp", gs.preview_hunk, "Preview uncommitted change")
        map("<leader>gs", gs.stage_hunk, "Stage change under cursor")
        map("<leader>gr", gs.reset_hunk, "Discard change under cursor")
        map("<leader>gb", gs.blame_line, "Blame line")
      end,
    },
  },
  {
    "nvim-mini/mini.diff",
    lazy = false,
    config = function()
      require("mini.diff").setup({
        source = main_branch_source(),
        view = {
          style = "sign",
          -- Thin bar: line differs from main.
          signs = { add = "│", change = "│", delete = "_" },
          priority = 5,
        },
        mappings = {
          -- Staging is done with gitsigns. Disable mini.diff's edit keys.
          apply = "",
          reset = "",
          textobject = "",
          goto_first = "[H",
          goto_prev = "[h",
          goto_next = "]h",
          goto_last = "]H",
        },
      })
      vim.keymap.set("n", "<leader>gd", function() require("mini.diff").toggle_overlay(0) end,
        { desc = "Git: Show diff with main inline" })
      vim.keymap.set("n", "<leader>gf", pick_changed_files, { desc = "Git: Pick file changed vs main" })
      -- ]q / [q (Neovim defaults) step through the list, across files.
      vim.keymap.set("n", "<leader>gq", branch_hunks_to_qf, { desc = "Git: Quickfix list of changes vs main" })
    end,
  },
}
