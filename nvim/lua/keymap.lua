vim.g.mapleader = ' '


vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')


vim.keymap.set({ 'n' }, '<C-h>', ':bp<CR>')
vim.keymap.set({ 'n' }, '<C-l>', ':bn<CR>')

-- b
vim.keymap.set({ 'n' }, '<leader>bd', ':bd<CR>')
vim.keymap.set({ 'n' }, '<leader>bb', ':bdelete!<CR>')
vim.keymap.set({ 'n' }, '<leader>bl', ":Gitsigns blame_line<CR>")
vim.keymap.set({ 'n' }, '<S-e>', '$')

-- c
vim.keymap.set({ 'n' }, '<leader>cg', '"+y')

-- d
vim.keymap.set('n', '<leader>dt', 'yitvatp')

--e
vim.keymap.set({ 'n' }, '<leader>ee', ':Pick buffers<CR>')
vim.keymap.set({ 'n' }, '<leader>ef', ':Pick files<CR>')
vim.keymap.set({ 'n' }, '<leader>eg', ':Pick grep_live<CR>')
vim.keymap.set({ 'n' }, '<leader>EE', ':e .<CR>')
vim.keymap.set({ 'n' }, '<leader>ec', ':e ~/.config/nvim/init.lua<CR>')
vim.keymap.set({ 'n' }, '<leader>ek', ':e ~/.config/nvim/lua/keymap.lua<CR>')
vim.keymap.set({ 'n' }, '<leader>en', vim.diagnostic.goto_next)
vim.keymap.set({ 'n' }, '<leader>eN', vim.diagnostic.goto_prev)
vim.keymap.set({ 'n' }, '<S-e>', '$')
vim.keymap.set({ 'n' }, '<S-b>', '0')

-- f
vim.keymap.set({ 'n' }, '<leader>ff', ':Oil --float<CR>')

--g
vim.keymap.set('n', '<leader>gl', vim.diagnostic.open_float, { desc = "Show diagnostics for current line" })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP definition' })

-- i
vim.keymap.set('n', '<leader>it', 'i< /><Esc>hh')

-- k
-- vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP hover' })


local peek_win
local peek_kind
local peek_source_buf
local peek_source_pos
local peek_focused = false

local function close_peek()
  if peek_win and vim.api.nvim_win_is_valid(peek_win) then
    vim.api.nvim_win_close(peek_win, true)
  end
  peek_win = nil
  peek_kind = nil
  peek_source_buf = nil
  peek_source_pos = nil
  peek_focused = false
end

local function lsp_hover_custom()
  if peek_kind == 'hover' and peek_win and vim.api.nvim_win_is_valid(peek_win) then
    peek_focused = true
    vim.api.nvim_set_current_win(peek_win)
    return
  end
  close_peek()
  peek_source_buf = vim.api.nvim_get_current_buf()
  peek_source_pos = vim.api.nvim_win_get_cursor(0)

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local encoding = clients[1] and clients[1].offset_encoding or 'utf-16'
  local params = vim.lsp.util.make_position_params(0, encoding)

  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if err or not result or not result.contents then
      return
    end

    local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    local _, win = vim.lsp.util.open_floating_preview(lines, 'markdown', {
      border = 'rounded',
    })
    peek_win = win
    peek_kind = 'hover'
    peek_focused = false
  end)
end

local function lsp_definition_peek()
  if peek_kind == 'definition' and peek_win and vim.api.nvim_win_is_valid(peek_win) then
    peek_focused = true
    vim.api.nvim_set_current_win(peek_win)
    return
  end
  close_peek()
  peek_source_buf = vim.api.nvim_get_current_buf()
  peek_source_pos = vim.api.nvim_win_get_cursor(0)

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local encoding = clients[1] and clients[1].offset_encoding or 'utf-16'
  local params = vim.lsp.util.make_position_params(0, encoding)

  vim.lsp.buf_request_all(0, 'textDocument/definition', params, function(results)
    for _, response in pairs(results) do
      local location = response.result and response.result[1]
      if location then
        local uri = location.uri or location.targetUri
        local range = location.range or location.targetSelectionRange
        local bufnr = vim.uri_to_bufnr(uri)
        vim.fn.bufload(bufnr)
        peek_win = vim.api.nvim_open_win(bufnr, false, {
          relative = 'cursor', row = 1, col = 0,
          width = math.min(100, vim.o.columns - 4),
          height = 15, style = 'minimal', border = 'rounded',
        })
        vim.api.nvim_win_set_cursor(peek_win, { range.start.line + 1, range.start.character })
        peek_kind = 'definition'
        peek_focused = false
        return
      end
    end
    vim.notify('No definition found')
  end)
end

vim.keymap.set('n', '<S-k>', lsp_hover_custom, { desc = 'LSP hover' })
vim.keymap.set('n', '<S-l>', lsp_definition_peek, { desc = 'Peek definition' })

local peek_group = vim.api.nvim_create_augroup('lsp_peek_close', { clear = true })
vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
  group = peek_group,
  callback = function()
    if not peek_win or not vim.api.nvim_win_is_valid(peek_win)
        or peek_focused
        or vim.api.nvim_get_current_buf() ~= peek_source_buf then
      return
    end

    local position = vim.api.nvim_win_get_cursor(0)
    if position[1] ~= peek_source_pos[1] or position[2] ~= peek_source_pos[2] then
      close_peek()
    end
  end,
})

-- l
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.keymap.set('n', '<leader>lhh', ":LspClangdSwitchSourceHeader<CR>")

--m
vim.keymap.set('n', '<leader>ms', 'o<Esc>yy20P<Esc>') --make space

-- o
vim.keymap.set('n', '<leader>ot', 'o< /><Esc>hh')
vim.keymap.set('n', '<leader><S-o>t', 'O< /><Esc>hh')
vim.keymap.set({ 'n' }, '<leader>ooo', ':w<CR>:so ~/.config/nvim/init.lua<CR>:so<CR>')

-- q
vim.keymap.set('n', '<leader>qq', ':q!<CR>')

-- t
vim.keymap.set('n', 'tt', ':vsplit<CR><C-w>l:term<CR>a')

-- w
vim.keymap.set('n', '<leader>ww', ':w<CR>zz')

-- y
vim.keymap.set({ 'x', 'n' }, '<leader>y', '"+y')
