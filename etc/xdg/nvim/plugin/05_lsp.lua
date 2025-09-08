vim.api.nvim_set_hl(0, 'LspReferenceRead', { link = 'Search' })
vim.api.nvim_set_hl(0, 'LspReferenceText', { link = 'Search' })
vim.api.nvim_set_hl(0, 'LspReferenceWrite', { link = 'Search' })

vim.api.nvim_set_hl(0, 'ComplMatchIns', {})
vim.api.nvim_set_hl(0, 'PmenuMatch', { link = 'Pmenu' })
vim.api.nvim_set_hl(0, 'PmenuMatchSel', { link = 'PmenuSel' })

local function keymap(lhs, rhs, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
end

local support_completion = function( client, bufnr)
  vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy', 'popup' }
  vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  vim.keymap.set(
    'i',
    '<C-Space>',
    vim.lsp.completion.get,
    { buffer = bufnr, desc = "Trigger lsp completion"
 })
 end


vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP Attach',
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local bufnr = event.buf
      -- Enable completion
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      support_completion(client, bufnr)

    end
  end
})

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    local server_configs = vim.iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
        :map(function(file)
          return vim.fn.fnamemodify(file, ':t:r')
        end)
        :totable()
    vim.lsp.enable(server_configs)
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  desc = 'LSP Detaching',
  group = vim.api.nvim_create_augroup("UserLspDetach", { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local client_id = event.data.client_id
    -- Get the detaching client
    local client = vim.lsp.get_client_by_id(client_id)
    -- Remove the autocommand to format the buffer on save, if it exists
    if client:supports_method('textDocument/formatting') then
      vim.api.nvim_clear_autocmds({
        event = 'BufWritePre',
        buffer = bufnr,
      })
    end
  end,
})

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.edit(vim.lsp.log.get_filename())
end, {})

vim.api.nvim_create_user_command("LspHandlers", function()
  require('scratch').show(vim.tbl_keys(vim.lsp.handlers), 'LSP Handlers')
end, {})

vim.api.nvim_create_user_command("LspNames", function()
  local show = require('scratch').show
  local curBuf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = curBuf })
  local client_names = vim.tbl_map(function(client) return client.name end, clients)
  show(client_names, 'LSP Names')
end, {})

vim.api.nvim_create_user_command("LspServerCapabilities", function()
  local show = require('scratch').show
  local curBuf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = curBuf })[1]
  local capabilities = client.server_capabilities
  --vim.print(vim.tbl_keys(client))
  --vim.notify(client.name)
  show(vim.inspect(capabilities), 'LSP Server Capabilities')
end, {})

