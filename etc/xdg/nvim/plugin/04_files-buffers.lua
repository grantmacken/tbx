--[[
04_files-buffers.lua
file and buffer management
includes
 - oil.nvim,
 - mini.bufremove,
 - fzf-lua
--]] -- File: 04_files-buffers.lua

local keymap = function(lhs, rhs, desc, mode)
  mode = mode or 'n'
  local opt = { desc = desc }
  vim.keymap.set(mode, lhs, rhs, opt)
end

local ok_oil, oil = pcall(require, 'oil')
if ok_oil then
  oil.setup({
    default_file_explorer = true,
    columns = {	-
      "icon",
    },
    prompt_save_on_select_new_entry = true,
    skip_confirm_for_simple_edits = true,
    view_options = { show_hidden = true },
    use_default_keymaps = true,
  })
  keymap('-', oil.open, ' [oil] open current directory', 'n')
end

local ok_bufremove, bufremove = pcall(require, 'mini.bufremove')
if ok_bufremove then
  bufremove.setup({
    -- Options for buffer removal
    silent = true, -- Don't show messages on buffer emoval
    force = false, -- Don't force delete buffers with unsaved changes
  })	
  keymap('<Leader>bd', bufremove.delete, 'bufremove: [d]elete current buffer', 'n')
end

local ok_fzf, fzf = pcall(require, 'fzf-lua')
if ok_fzf then
  vim.api.nvim_create_user_command('Files', fzf.files, { desc = '[FZF] Find Files' })
  keymap('<Leader>ff', vim.cmd.Files, 'Find [f]iles')
  vim.api.nvim_create_user_command('Directories', fzf.zoxide, { desc = '[FZF] List recent Directories' })
  keymap('<Leader>fr', vim.cmd.Directories, 'Find [R]ecent directories')
  vim.api.nvim_create_user_command('GFiles', fzf.git_files, { desc = '[FZF] Find Git Files' })
  keymap('<Leader>fg', vim.cmd.GFiles, 'Find [g]it files')
  vim.api.nvim_create_user_command('Buffers', fzf.buffers, { desc = '[F]ind Open Buffers' })
  keymap('<Leader>fb', vim.cmd.Buffers, 'Find [b]uffers')
  vim.api.nvim_create_user_command('LiveGrep', fzf.live_grep, { desc = 'FZF: Live Grep' })
  keymap('<Leader>fl', vim.cmd.LiveGrep, 'Find with [L]ive grep')
  -- vim.api.nvim_create_user_command('Grep', fzf.grep, { desc = '[FZF] Grep' })
  vim.api.nvim_create_user_command('GrepCword', fzf.grep_cword, { desc = '[FZF] Grep Cword' })
  keymap('<Leader>fgc', vim.cmd.GrepCword, 'Find instances of [c]urrent word under cursor')
  vim.api.nvim_create_user_command('Jumps', fzf.jumps, { desc = '[FZF] Jumps' })
  vim.api.nvim_create_user_command('Marks', fzf.marks, { desc = '[FZF] Marks' })
  vim.api.nvim_create_user_command('Tags', fzf.tagstack, { desc = '[FZF] Tagstack' })
end
