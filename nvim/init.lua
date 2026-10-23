-- Breadcrumb for the starter configuration; theme loading is below.

-- The external system-theme CLI selects this file at runtime.
local theme_file = vim.fn.expand("~/.config/system-theme/current/nvim.lua")
if vim.fn.filereadable(theme_file) == 1 then
  pcall(dofile, theme_file)
end

-- Let the theme CLI update this instance without restarting Neovim.
local runtime_dir = vim.env.XDG_RUNTIME_DIR or "/tmp"
local server_socket = runtime_dir .. "/nvim-theme-" .. vim.fn.getpid() .. ".sock"
pcall(vim.fn.serverstart, server_socket)
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(vim.fn.delete, server_socket)
  end,
})
