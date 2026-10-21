-- Highlights every visible occurrence of the symbol under the cursor after the cursor stops moving.
-- With an LSP server that supports documentHighlight, only real references of the symbol get highlighted.
-- Without one, every match of the word under the cursor gets highlighted.

-- Delay in ms before CursorHold fires. The default of 4000 ms is too slow for this.
vim.opt.updatetime = 250

local group = vim.api.nvim_create_augroup("UserSymbolHighlight", { clear = true })

local function clear()
  vim.lsp.buf.clear_references()
  local id = vim.w.symbol_match_id
  if id then
    pcall(vim.fn.matchdelete, id)
    vim.w.symbol_match_id = nil
  end
end

vim.api.nvim_create_autocmd("CursorHold", {
  group = group,
  callback = function(args)
    clear()
    if vim.bo[args.buf].buftype ~= "" then return end
    if #vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/documentHighlight" }) > 0 then
      vim.lsp.buf.document_highlight()
      return
    end
    local word = vim.fn.expand("<cword>")
    if word:match("^[%w_]+$") then
      vim.w.symbol_match_id = vim.fn.matchadd("LspReferenceText", [[\V\<]] .. word .. [[\>]], -1)
    end
  end,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
  group = group,
  callback = clear,
})

-- Reloads a buffer when its file changes on disk.
-- 'autoread' only acts when Neovim runs :checktime, so these events trigger it.
-- A buffer with unsaved changes is not reloaded. Neovim asks what to do instead.
vim.opt.autoread = true

local reload_group = vim.api.nvim_create_augroup("UserAutoReload", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermLeave" }, {
  group = reload_group,
  callback = function()
    -- :checktime is not permitted in the command-line window.
    if vim.fn.getcmdwintype() == "" then vim.cmd("checktime") end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = reload_group,
  callback = function(args)
    vim.notify("Reloaded from disk: " .. vim.fn.fnamemodify(args.file, ":~:."), vim.log.levels.INFO)
  end,
})
