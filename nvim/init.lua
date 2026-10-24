require('options')
require('keymap')


-- project specific configs

vim.opt.exrc = true


-- [[ Basic Autocommands ]].
-- See `:h lua-guide-autocommands`, `:h autocmd`, `:h nvim_create_autocmd()`

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  callback = function()
    vim.hl.on_yank()
  end,
})


vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.lua", "*.cpp", "*.h", "*.html", "*.ts", "*.tsx", "*.js", "*.jsx", "*.go" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.md" },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local prettier = vim.fn.exepath("prettier")
    if prettier == "" then return end
    local out = vim.fn.systemlist({ prettier, "--stdin-filepath", vim.api.nvim_buf_get_name(0) }, lines)
    if vim.v.shell_error == 0 then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
    end
  end,
})


-- [[ Create user commands ]]
-- See `:h nvim_create_user_command()` and `:h user-commands`

-- Create a command `:GitBlameLine` that print the git blame for the current line
vim.api.nvim_create_user_command('GitBlameLine', function()
  local line_number = vim.fn.line('.') -- Get the current line number. See `:h line()`
  local filename = vim.api.nvim_buf_get_name(0)
  print(vim.fn.system({ 'git', 'blame', '-L', line_number .. ',+1', filename }))
end, { desc = 'Print the git blame for the current line' })

vim.cmd('packadd! nohlsearch')

vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  -- { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/pi314ever/oil.nvim" },
  { src = "https://github.com/nvim-mini/mini.surround" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  { src = "https://github.com/nvim-mini/mini.pick" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/hrsh7th/nvim-cmp" },
  { src = "https://github.com/hrsh7th/cmp-path" },
  { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})


require("gitsigns").setup({
  numhl = true,
  attach_to_untracked = true
})
require("oil").setup({
  view_options = {
    show_hidden = true
  },
  columns = {},
})

require("mini.surround").setup({
  respect_selection_type = true,
  custom_surroundings = {
    ['L'] = {
      output = { left = '', right = '' },
    },
  },
})


require('nvim-treesitter.configs').setup({
  -- Install parsers automatically
  ensure_installed = {
    "lua",
    "cpp",
    "python",
    "javascript",
    "typescript",
    "tsx",
    "html",
    "css",
    "go",
    "gomod",
    "gowork",
    "json",
    "bash",
    "nix",
  },

  highlight = {
    enable = true,                             -- enable treesitter-based syntax highlighting
    additional_vim_regex_highlighting = false, -- disables legacy regex highlighting
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<CR>",      -- start selection
      node_incremental = "<Tab>",   -- expand to next node
      node_decremental = "<S-Tab>", -- shrink selection
      scope_incremental = "<S-CR>", -- expand to parent scope
    },
  },

  indent = {
    enable = true, -- enable treesitter-based indentation
  },
})


-- setup completion
local cmp = require('cmp')

cmp.setup({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Enter to confirm selection
    ['<C-Space>'] = cmp.mapping.complete(),             -- Trigger completion manually
    -- ['<Esc>'] = cmp.mapping.abort(),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'path' },
  })
})




require('mini.pairs').setup({
  check_ts = true,                              -- enable Tree-sitter checks for context awareness
  ts_config = {
    lua = { "string" },                         -- don't auto-close inside Lua strings
    cpp = { "string_literal", "char_literal" }, -- don't auto-close inside C++ strings/chars
  },
  disable_filetype = { "text", "markdown" },    -- disable autopairs in non-code buffers
})

require('mini.pick').setup({})


local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim", "hl" } },
      workspace = {
        library = {
          vim.fn.stdpath("config"),
          vim.api.nvim_get_runtime_file("", true),
        },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable({
  "gopls",
  "html",
  "cssls",
  "jsonls",
  "lua_ls",
  "nixd",
  "pyright",
  "clangd",
  -- "typescript",
  "ts_ls",
  "tailwind",
  "texlab",
})

vim.lsp.config("clangd", {
  capabilities = capabilities,
})

vim.lsp.config('typescript', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' },
})

vim.lsp.config('tailwind', {
  cmd = { 'tailwindcss-language-server', '--stdio' },
  filetypes = { 'ts', 'typescript', 'css', 'typescriptreact', 'tsx' },
  root_markers = { 'package.json' },
})

-- nixd resolves <nixpkgs> through nix.settings.nix-path (flake-pinned).
vim.lsp.config("nixd", {
  capabilities = capabilities,
  settings = {
    nixd = {
      nixpkgs = { expr = "import <nixpkgs> { }" },
      formatting = { command = { "nixfmt" } },
    },
  },
})


vim.pack.add({ { src = "https://github.com/windwp/nvim-ts-autotag" } })
require('nvim-ts-autotag').setup({
  opts = {
    enable_close_on_slash = true,
  }
})


-- The system-theme CLI selects the active theme file and reloads running
-- instances through the socket below, so no restart is needed.
local theme_file = vim.fn.expand("~/.config/system-theme/current/nvim.lua")
if vim.fn.filereadable(theme_file) == 1 then
  pcall(dofile, theme_file)
end

local runtime_dir = vim.env.XDG_RUNTIME_DIR or "/tmp"
local server_socket = runtime_dir .. "/nvim-theme-" .. vim.fn.getpid() .. ".sock"
pcall(vim.fn.serverstart, server_socket)
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(vim.fn.delete, server_socket)
  end,
})
