-- Tab & Indentation Settings
vim.opt.tabstop = 4        -- Number of visual spaces per tab
vim.opt.softtabstop = 4    -- Number of spaces inserted when pressing Tab
vim.opt.shiftwidth = 4     -- Number of spaces used for auto-indenting (e.g. >> or <<)
vim.opt.expandtab = true   -- Convert tabs into spaces

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Gutter grows to 3 sign columns: diagnostics, diff with main, uncommitted changes.
vim.opt.signcolumn = "auto:1-3"

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

-- "noinsert" preselects the first item but does not insert it until it is accepted.
vim.opt.completeopt = { "menuone", "noinsert", "popup", "fuzzy" }
