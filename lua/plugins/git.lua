-- Two git gutters:
--   mini.diff: every line that differs from the main branch (commits on this branch and uncommitted edits).
--   gitsigns:  only changes that are not committed yet. Staged and unstaged changes use different symbols.

-- Branches to compare with, in order. The first one that exists is used.
local BASE_BRANCHES = { "main", "master", "origin/main", "origin/master" }

-- Returns the file content at the merge-base of HEAD and the main branch, or nil.
-- nil means: not in a git repo, no main branch, or the file does not exist at that commit.
local function main_branch_text(path)
  local dir = vim.fs.dirname(path)
  local function git(args)
    local res = vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
    if res.code ~= 0 then return nil end
    return res.stdout
  end
  local root = git({ "rev-parse", "--show-toplevel" })
  if not root then return nil end
  for _, branch in ipairs(BASE_BRANCHES) do
    local base = git({ "merge-base", "HEAD", branch })
    if base then
      local rel = vim.fs.relpath(vim.trim(root), path)
      if not rel then return nil end
      -- A file that is new on this branch has no content at the base, so every line shows as added.
      return git({ "show", vim.trim(base) .. ":" .. rel }) or ""
    end
  end
  return nil
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
    end,
  },
}
