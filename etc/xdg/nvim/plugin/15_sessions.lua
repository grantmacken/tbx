vim.o.sessionoptions          = 'curdir,folds,globals,help,tabpages,terminal,winsize'

local resession_ok, resession = pcall(require, "resession")
if not resession_ok then
  vim.notify('Resession not found, skipping session management', vim.log.levels.WARN)
  return
end

resession.setup({
  tab_buf_filter = function(tabpage, bufnr)
    local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
    -- ensure dir has trailing /
    dir = dir:sub(-1) ~= "/" and dir .. "/" or dir
    return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
  end
})

local keymap = function(lhs, rhs, desc, mode)
  mode = mode or 'n'
  local opt = { desc = desc }
  vim.keymap.set(mode, lhs, rhs, opt)
end

-- Make Session --> ms
keymap("<leader>ms", resession.save_tab, 'Save session')
keymap("<leader>ml", resession.load, 'Load session')
keymap("<leader>md", resession.delete, 'Delete session')

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    -- Always save a special session named "last"
    resession.save("last")
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Always load  "last"
    resession.load("last")
  end,
})
