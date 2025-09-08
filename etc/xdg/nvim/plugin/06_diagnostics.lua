---@see h: vim.diagnostic.config
---@see h: vim.diagnostic.handlers
---
-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
assert(show_handler)
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
  show = function(ns, bufnr, diagnostics, opts)
    table.sort(diagnostics, function(diag1, diag2)
      return diag1.severity > diag2.severity
    end)
    return show_handler(ns, bufnr, diagnostics, opts)
  end,
  hide = hide_handler,
}
---

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '»',
    }
  },
  underline = false,
  virtual_text = false,
  virtual_lines = {
    severity = {
      min = vim.diagnostic.severity.HINT,
    },
    update_in_insert = false,
    current_line = true,
    -- Open the location list on every diagnostic change (warnings/errors only).
    loclist = {
      open = true,
      severity = { min = vim.diagnostic.severity.WARN },
    }
  },
})

-- vim.diagnostic.enable(true)

--Whenever the |location-list| is opened, the following `show` handler will show
--the most recent diagnostics:

vim.diagnostic.handlers.loclist = {
  show = function(_, _, _, opts)
    -- Generally don't want it to open on every update
    opts.loclist.open = opts.loclist.open or false
    local winid = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist(opts.loclist)
    vim.api.nvim_set_current_win(winid)
  end
}
