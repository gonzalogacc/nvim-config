-- Tab & Indentation Settings
vim.opt.tabstop = 4        -- Number of visual spaces per tab
vim.opt.softtabstop = 4    -- Number of spaces inserted when pressing Tab
vim.opt.shiftwidth = 4     -- Number of spaces used for auto-indenting (e.g. >> or <<)
vim.opt.expandtab = true   -- Convert tabs into spaces

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Splits open to the right / below (like VS Code)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Search: case-insensitive unless the query has a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Disable netrw (built-in file explorer); nvim-tree replaces it
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit true colors for colorschemes
vim.opt.termguicolors = true

