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
          local map = function(keys, func, desc, mode, expr)
            vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc, expr = expr })
          end

          -- Native completion. Accepting an auto-import item also inserts its import line.
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          -- Servers only list "." and similar as trigger characters. Adding identifier characters opens the menu while typing a name.
          if client and client:supports_method("textDocument/completion") then
            local triggers = client.server_capabilities.completionProvider.triggerCharacters or {}
            for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
              table.insert(triggers, c)
            end
            client.server_capabilities.completionProvider.triggerCharacters = triggers
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
          end

          -- VS Code style menu keys: Tab or Enter accepts, Ctrl+Space opens the menu.
          map("<Tab>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<Tab>" end, "Accept completion", "i", true)
          map("<CR>", function() return vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 and "<C-y>" or "<CR>" end, "Accept completion", "i", true)
          map("<C-Space>", vim.lsp.completion.get, "Open completion menu", "i")

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

          -- Quick fix / import menu
          map("<leader>.", vim.lsp.buf.code_action, "Quick fix / import menu")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")

          -- Rename symbol
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")

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
      -- ty finds <project root>/.venv by itself (uv default). It supplies type diagnostics,
      -- auto-import completion, and "import X" quick fixes for undefined names.
      -- Ruff supplies lint and import sorting only. ty supplies hover documentation.
      vim.lsp.config("ruff", {
        -- ty already reports undefined names (F821).
        init_options = { settings = { lint = { ignore = { "F821" } } } },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
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
      vim.lsp.enable("ty")
      vim.lsp.enable("ruff")
      vim.lsp.enable("clangd")
      vim.lsp.enable("lua_ls")
    end,
  },
}
