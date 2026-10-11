return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function() return vim.fn.executable("make") == 1 end,
    },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<leader><leader>", "<cmd>Telescope buffers<CR>", desc = "Switch buffer" },
    { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in current file" },
    { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Search word under cursor" },
    { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
    { "<leader>f.", "<cmd>Telescope resume<CR>", desc = "Resume last search" },
    -- VS Code style: Cmd+P / Cmd+Shift+F (Super key; needs a GUI or a terminal that forwards it)
    { "<D-p>", "<cmd>Telescope find_files<CR>", mode = { "n", "i" }, desc = "Find files" },
    { "<D-S-f>", "<cmd>Telescope live_grep<CR>", mode = { "n", "i" }, desc = "Search in files" },
    { "<D-F>", "<cmd>Telescope live_grep<CR>", mode = { "n", "i" }, desc = "Search in files" },
    -- Fallbacks that work in any terminal (including tmux)
    { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<C-S-f>", "<cmd>Telescope live_grep<CR>", desc = "Search in files" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })
    pcall(telescope.load_extension, "fzf")
  end,
}
