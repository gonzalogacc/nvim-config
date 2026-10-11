return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
    { "<leader>E", "<cmd>NvimTreeFindFile<CR>", desc = "Reveal current file in tree" },
  },
  config = function()
    require("nvim-tree").setup({
      view = { width = 30 },
      -- Opening a directory is handled by the VimEnter autocmd below
      hijack_directories = { enable = false },
      -- Follow the file you're editing: expand folders and highlight it
      update_focused_file = { enable = true },
      renderer = {
        highlight_opened_files = "name",
        -- Plain symbols so it works without a Nerd Font
        icons = {
          show = { file = false, folder = false, folder_arrow = true, git = true },
          glyphs = {
            folder = { arrow_closed = "▸", arrow_open = "▾" },
            git = {
              unstaged = "M", staged = "S", unmerged = "U", renamed = "R",
              untracked = "?", deleted = "D", ignored = "-",
            },
            bookmark = "*",
            modified = "+",
            hidden = "h",
          },
        },
      },
    })

    -- Make the current-file line clearly visible in the tree
    vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { link = "Visual" })

    -- `nvim <dir>`: cd into it and open the tree on the side
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        if vim.fn.isdirectory(data.file) ~= 1 then return end
        vim.cmd.enew()
        vim.cmd.bw(data.buf)
        vim.cmd.cd(data.file)
        require("nvim-tree.api").tree.open()
      end,
    })
  end,
}
