-- CLUES

local resession_ok, resession = pcall(require, "resession")
if not resession_ok then
  vim.notify('Resession not found, skipping session management', vim.log.levels.WARN)
  return
end

local ok_clues, clue = pcall(require, 'mini.clue')
if not ok_clues then
  vim.notify('mini.clue not found, skipping', vim.log.levels.WARN)
  return
end

  local clue_triggers = {
    -- Builtins
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    -- Leader triggers.
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "i", keys = "<C-x>" },
    -- GoTo  withMoves
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    -- Custom extras
    mark_clues,
  }

  local leader_group_clues = {
    --{ mode = 'n', keys = '<Leader>a', desc = '+AiCopilotChat' },
    { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
    --{ mode = 'n', keys = '<Leader>J', desc = '+Split[J]oin' },
    --{ mode = 'n', keys = '<Leader>s', desc = '+[S]earch' },
    --{ mode = 'n', keys = '<Leader>d', desc = '+Diagnostic' },
    { mode = 'n', keys = '<Leader>f', desc = '+[[F]uzzyFind' },
    { mode = 'n', keys = '<Leader>m', desc = '+[M]akeSession' },
    --{ mode = 'n', keys = '<Leader>t', desc = '+Toggle' },
  }

  local clue_window = {
    delay = 500, -- Delay in milliseconds before showing the clue window
    scroll_down = '<C-d>',
    scroll_up = '<C-u>',
    config = function(bufnr)
      local max_width = 0
      for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        max_width = math.max(max_width, vim.fn.strchars(line))
      end
      -- Keep some right padding.
      max_width = max_width + 2
      return {
        -- Dynamic width capped at 70.
        width = math.min(70, max_width),
      }
    end,
  }

  clue.setup({
    window = clue_window,
    triggers = clue_triggers,
    clues = {
      leader_group_clues,
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),
    },
  })
