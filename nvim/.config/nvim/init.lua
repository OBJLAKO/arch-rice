-- =========================================
-- Neovim init.lua — Mono/Dark Pro (quiet, no warnings)
-- Менеджер: lazy.nvim
-- =========================================

pcall(function() if vim.loader then vim.loader.enable() end end)

-- ── Leader / базовые глобалы
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_ruby_provider, vim.g.loaded_perl_provider = 0, 0

-- ── Опции
local o, wo, bo = vim.o, vim.wo, vim.bo
o.termguicolors = true
o.clipboard = "unnamedplus"
o.mouse = "a"
o.updatetime = 250
o.timeoutlen = 400
o.ignorecase, o.smartcase = true, true
o.incsearch, o.hlsearch = true, true
o.splitbelow, o.splitright = true, true
o.completeopt = "menu,menuone,noselect"
o.scrolloff = 6
wo.number, wo.relativenumber = true, true
wo.signcolumn = "yes"
bo.expandtab, bo.shiftwidth, bo.tabstop = true, 2, 2

-- ── Маппинги
local map = vim.keymap.set
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank → system" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- ── Автокоманды
local aug = vim.api.nvim_create_augroup
local acmd = vim.api.nvim_create_autocmd
acmd("TextYankPost",
  { group = aug("YankHL", { clear = true }), callback = function() vim.highlight.on_yank { timeout = 120 } end })
acmd("BufWritePre",
  { callback = function() pcall(function() require("conform").format({ lsp_fallback = true }) end) end })

-- ── Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ── Плагины
require("lazy").setup({
  -- База
  { "nvim-lua/plenary.nvim",       lazy = true },
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Тема: строгий тёмный (без неона/стекла на редакторе)
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      styles = { sidebars = "dark", floats = "dark" },
      on_colors = function(c)
        c.bg         = "#0b0c0e" -- плотный фон редактора
        c.bg_sidebar = "#0e1013"
        c.bg_float   = "#0e1013"
        c.border     = "#2a2e34"
      end,
    }
  },

  -- UI
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "auto", section_separators = "", component_separators = "" } }
  },
  { "folke/which-key.nvim",          opts = { delay = 200 } },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = { scope = { enabled = false }, indent = { char = "│" } }
  },

  -- Файловый менеджер
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    opts = { filesystem = { filtered_items = { hide_dotfiles = false, hide_gitignored = false } }, window = { width = 34 } }
  },

  -- Поиск/навигация
  { "nvim-telescope/telescope.nvim", tag = "0.1.6",         dependencies = { "nvim-lua/plenary.nvim" } },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = function()
      return vim.fn.executable("make") ==
          1
    end
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects", "nvim-treesitter/nvim-treesitter-context" },
    opts = { highlight = { enable = true }, indent = { enable = true }, incremental_selection = { enable = true } }
  },

  -- Редактирование
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.comment").setup()
      require("mini.ai").setup()
    end
  },
  { "windwp/nvim-ts-autotag",   opts = {} },
  { "folke/todo-comments.nvim", dependencies = "nvim-lua/plenary.nvim", opts = {} },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = { add = { text = "│" }, change = { text = "│" }, delete = { text = "▁" }, topdelete = { text = "▔" }, changedelete = { text = "│" } }
    }
  },
  { "sindrets/diffview.nvim",  dependencies = "nvim-lua/plenary.nvim" },
  { "tpope/vim-fugitive" },

  -- LSP/Completion (PIN lspconfig → без депрекейт-спама)
  { "neovim/nvim-lspconfig",   version = "v0.1.7" }, -- стабильный тег ДО предупреждений
  { "williamboman/mason.nvim", opts = {} },

  -- ensure_installed формируем с учётом того, что у Mason реально есть
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function()
      local servers_base = {
        "lua_ls", "jsonls", "html", "cssls", "eslint", "yamlls", "dockerls",
        "gopls", "rust_analyzer", "pyright", "clangd", "marksman", "omnisharp",
      }
      local ok, mlsp = pcall(require, "mason-lspconfig")
      if not ok then return { ensure_installed = servers_base } end
      local avail = mlsp.get_available_servers()
      local function has(name)
        for _, s in ipairs(avail) do if s == name then return true end end
        return false
      end
      local ts = has("ts_ls") and "ts_ls" or (has("tsserver") and "tsserver" or nil)
      if ts then table.insert(servers_base, ts) end
      return { ensure_installed = servers_base }
    end
  },

  { "folke/neodev.nvim", opts = {} }, -- Lua API знание

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip", "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets"
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
        }),
        sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" }, { name = "path" } }),
      })
    end
  },

  -- Форматирование
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "yamlfmt" },
        toml = { "taplo" },
        css = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        python = { "black" },
        go = { "gofmt", "goimports" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        cs = { "csharpier" },
        markdown = { "prettierd", "prettier" }
      }
    }
  },
}, {
  checker = { enabled = true },
  performance = { rtp = { disabled_plugins = { "gzip", "tarPlugin", "zipPlugin", "matchit", "matchparen" } } }
})

-- ── Тема
vim.cmd.colorscheme("tokyonight")

-- ── Telescope хоткеи
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Files" })
map("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Grep" })
map("n", "<leader>fb", function() require("telescope.builtin").buffers() end, { desc = "Buffers" })
map("n", "<leader>fh", function() require("telescope.builtin").help_tags() end, { desc = "Help" })

-- ── Диагностика
vim.diagnostic.config({ virtual_text = { prefix = "●", spacing = 2 }, signs = true, underline = true })

-- ── LSP: on_attach
local function on_attach(_, bufnr)
  local function bmap(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end
  bmap("n", "gd", vim.lsp.buf.definition, "Go to def")
  bmap("n", "gD", vim.lsp.buf.declaration, "Declaration")
  bmap("n", "gi", vim.lsp.buf.implementation, "Implementation")
  bmap("n", "gr", require("telescope.builtin").lsp_references, "References")
  bmap("n", "K", vim.lsp.buf.hover, "Hover")
  bmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  bmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
  bmap("n", "<leader>fd", function() require("telescope.builtin").diagnostics() end, "Diagnostics")
end

-- ── LSP (старый API, но pinned → без предупреждений)
local lspconfig    = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("neodev").setup({})

-- Lua
lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
      telemetry = { enable = false }
    }
  }
})

-- TypeScript: ts_ls (если есть) иначе tsserver
local util = require("lspconfig.util")
local ts_name = (lspconfig.ts_ls and "ts_ls") or (lspconfig.tsserver and "tsserver") or nil
if ts_name then
  lspconfig[ts_name].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    root_dir = util.root_pattern("tsconfig.json", "package.json", ".git"),
    single_file_support = false,
  })
end

-- Остальные
for _, server in ipairs({
  "jsonls", "html", "cssls", "eslint", "yamlls", "dockerls",
  "gopls", "rust_analyzer", "pyright", "clangd", "marksman", "omnisharp",
}) do
  if lspconfig[server] then
    lspconfig[server].setup({ on_attach = on_attach, capabilities = capabilities })
  end
end

-- ── Команды
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Format", function() require("conform").format({ lsp_fallback = true }) end, {})
