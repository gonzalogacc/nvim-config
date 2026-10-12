return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Diagnostic display setup with distinct glyphs/shapes for deuteranomaly accessibility
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✖",
            [vim.diagnostic.severity.WARN]  = "▲",
            [vim.diagnostic.severity.INFO]  = "ℹ",
            [vim.diagnostic.severity.HINT]  = "◆",
          },
        },
        virtual_text = {
          prefix = "●",
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Keymaps configured whenever an LSP client attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- Jump to definition / references
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
              builtin.lsp_references()
            else
              vim.lsp.buf.references()
            end
          end, "References")
          map("gy", vim.lsp.buf.type_definition, "Type definition")

          -- Hover doc & signatures
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<C-k>", vim.lsp.buf.signature_help, "Signature help")

          -- Refactoring & Actions
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")

          -- Diagnostic jumps
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })

      -- Mason package manager
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
      })

      -- Neovim 0.11 native LSP configuration
      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
            },
          },
        },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Enable servers
      vim.lsp.enable("pyright")
      vim.lsp.enable("clangd")
      vim.lsp.enable("lua_ls")
    end,
  },
}
