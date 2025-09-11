local tbl_cmd = { 'lua-language-server' }
local tbl_settings = {
  Lua = {
    runtime = {
      version = 'LuaJIT',
      path = vim.split(package.path, ';'),
    },
    diagnostics = {
      -- Get the language server to recognize the `vim` global, etc.
      globals = { 'vim' },
      disable = { 'duplicate-set-field', 'need-check-nil' },
      -- Don't make workspace diagnostic, as it consumes too much CPU and RAM
      workspaceDelay = -1,
    },
    -- Make the server aware of Neovim runtime files
    workspace = {
      checkThirdParty = false,
      library = { vim.env.VIMRUNTIME },
      ignoreSubmodules = true,
      -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
      -- library = vim.api.nvim_get_runtime_file("", true)
    },
    telemetry = {
      enable = false,
    },
    hint = { -- inlay hints
      enable = true,
    },
    codeLens = {
      enable = true,
    },
  }
}

return {
  cmd = tbl_cmd,
  filetypes = { 'lua' },
  root_markers = {
    '.git',
  },
  settings = tbl_settings,
}
