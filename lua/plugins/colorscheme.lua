return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      terminal_colors = true,
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = false,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true,
      contrast = "hard", -- "hard" contrast improves background/token separation
      overrides = {
        -- High-contrast, deuteranomaly-friendly diagnostic colors
        -- (Distinguishing cleanly between Error, Warn, Info, Hint)
        DiagnosticError = { fg = "#fb4934", bold = true },
        DiagnosticWarn  = { fg = "#fabd2f", bold = true },
        DiagnosticInfo  = { fg = "#83a598" },
        DiagnosticHint  = { fg = "#d3869b" },
        DiagnosticUnderlineError = { undercurl = true, sp = "#fb4934" },
        DiagnosticUnderlineWarn  = { undercurl = true, sp = "#fabd2f" },
        DiagnosticUnderlineInfo  = { undercurl = true, sp = "#83a598" },
        DiagnosticUnderlineHint  = { undercurl = true, sp = "#d3869b" },
        -- Symbol under cursor: background plus shape, so it does not depend on hue alone.
        -- Write = places that assign the symbol.
        LspReferenceText  = { bg = "#504945" },
        LspReferenceRead  = { bg = "#504945" },
        LspReferenceWrite = { bg = "#504945", underline = true, bold = true },
      },
    })
    vim.cmd("colorscheme gruvbox")
  end,
}
