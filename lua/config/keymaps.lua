-- General (non-plugin) keymaps go here.
-- Plugin keymaps live in their own spec under lua/plugins/.

local map = vim.keymap.set

-- Create splits
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Split vertical" })
map("n", "<leader>s", "<cmd>split<CR>", { desc = "Split horizontal" })
map("n", "<leader>q", "<C-w>q", { desc = "Close window" })

-- Move between windows
map("n", "<leader>h", "<C-w>h", { desc = "Window left" })
map("n", "<leader>l", "<C-w>l", { desc = "Window right" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })

-- Resize with Ctrl+arrows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Taller" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Shorter" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Narrower" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Wider" })

-- Equalize split sizes
map("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })

-- Search
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centered)" })
