-- Pins the enclosing function/class signature to the top of the window when its first line scrolls out of view.
-- Needs a treesitter parser for the filetype. Without one, nothing is shown.
return {
  "nvim-treesitter/nvim-treesitter-context",
  lazy = false,
  config = function()
    require("treesitter-context").setup({
      mode = "cursor",          -- Show the scopes that contain the cursor, not the scopes at the top line.
      max_lines = 3,            -- Nested scopes (class > def > inner def) use 1 line each, up to this limit.
      multiline_threshold = 1,  -- Show only the first line of a multi-line signature.
      trim_scope = "outer",     -- At the limit, drop the outermost scopes first.
    })

    -- A line below the context separates it from the code.
    vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#665c54" })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "#665c54" })

    vim.keymap.set("n", "[x", function()
      require("treesitter-context").go_to_context(vim.v.count1)
    end, { desc = "Jump to enclosing function/class" })
  end,
}
