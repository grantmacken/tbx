
vim.treesitter.start()
-- defaults to current buffer and language of the buffer
vim.notify(' - lua treesitter started')
if not vim.lsp.is_enabled( 'lua_ls' ) then
  vim.lsp.enable( 'lua_ls', true)
 vim.notify(' - lua-language-server is enabled')
 -- TODO not sure if I have to call below to activate lsp
 -- nvim_get_current_buf()
 -- could use get_clients({filter}) 
 vim.cmd.edit()
end
-- Auto-starts LSP when a buffer is opened,
