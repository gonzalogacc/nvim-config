return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local parsers = {
      "python",
      "lua",
      "c",
      "cpp",
      "vim",
      "vimdoc",
      "markdown",
      "markdown_inline",
    }

    -- Parser builds need the tree-sitter CLI. Without it, only the parsers bundled with Neovim are available.
    if vim.fn.executable("tree-sitter") == 1 then
      require("nvim-treesitter").install(parsers)
    end

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        -- vim.treesitter.start fails if no parser exists for the filetype.
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
