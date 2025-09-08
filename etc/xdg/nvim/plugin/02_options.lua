-- vim.cmd('filetype plugin indent on')      -- Enable all filetype plugins

-- WINDOW CHROME
vim.o.signcolumn     = "yes"
vim.o.showmode       = false    -- Dont show mode since we have a statusline
vim.o.showtabline    = 2        -- Always show tabline
vim.o.number         = true     -- Show line numbers
vim.o.relativenumber = true     -- Relative line numbers
vim.o.laststatus     = 3        -- Global statusline
vim.o.cmdheight      = 0        -- Hide command line unless needed
vim.o.ruler          = false    -- Don't show cursor position in command line
vim.o.winminwidth    = 5        -- Minimum window width
vim.opt.title        = true     -- Vim will change terminal title
vim.o.winborder      = 'double' -- Border style for floating windows
-- vim.opt.titlestring    = "%{getpid().':'.getcwd()}"

-- CLIPBOARD KEYBOARD MOUSE
vim.o.clipboard      = "unnamedplus" -- Sync with system clipboard
vim.o.timeoutlen     = 1000          -- modal keys --300
vim.o.ttimeoutlen    = 10
vim.o.mouse          = 'a'           -- Enable mouse for all available modes
vim.opt.spelllang    = { "en" }

-- EDITING BLING
vim.o.wrap           = false -- Display long lines as just one line
vim.o.breakindent    = true  -- Indent wrapped lines to match line start
vim.o.colorcolumn    = "120" -- Highlight current line
vim.o.cursorline     = true  -- Highlight current line
vim.o.expandtab      = true  -- Use spaces instead of tabs
vim.o.shiftround     = true  -- Round indent
vim.o.shiftwidth     = 2     -- Size of an indent
vim.o.scrolloff      = 10    -- Lines of context
vim.o.sidescrolloff  = 8     -- Columns of context
vim.o.smartindent    = true  -- Insert indents automatically
vim.o.smoothscroll   = true
vim.o.tabstop        = 4
vim.o.virtualedit    = "block" -- Allow cursor to move where there is no text in visual block mode
vim.opt.fillchars    = {
  foldopen = "",
  foldclose = "",
  fold = "-",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
--"▷ ⋯",
vim.o.list           = true -- Show some invisible characters (tabs...
 vim.opt.listchars    = {   nbsp = '‡', -- non-breaking space
  precedes = "«", -- left pointing double angle quotation mark
  extends = "»", -- right pointing double angle quotation mark
  eol = "↲", -- end of line
  tab = "⋯⋯", -- midline horizontal ellipsis
} -- ▶ helper symbols to show

vim.o.iskeyword      = '@,48-57,_,192-255,-' -- Treat dash separated words as a word text object

-- SPLITING WINDOWS
vim.opt.splitbelow   = true -- Put new windows below current
vim.opt.splitkeep    = "screen"
vim.opt.splitright   = true -- Put new windows right of current

-- SEARCHING
vim.o.smartcase      = true
vim.o.hlsearch       = true
vim.o.ignorecase     = true                             -- Ignore case when searching (use `\C` to force not doing that)
vim.o.inccommand     = "split"                          -- preview incremental substitute
vim.o.incsearch      = true                             -- Show search results while typing
:w
-- UNDO RESTORE
vim.o.shortmess      = 'FOSWaco'                        -- Disable certain messages from |ins-completion-menu|
--vim.o.shortmess     = 'aoOWFcSC'                      -- Reduce command line messages
--  vim.o.shada          = "'100,<50,s10,:1000,/100,@100,h" -- Limit what is stored in ShaDa file
vim.o.autowrite      = true                             -- Enable auto write
vim.o.backup         = false                            -- Don't store backup while overwriting the file
vim.o.undofile       = true                             -- Enable persistent undo (see also `:h undodir`)
vim.o.undolevels     = 10000                            -- 10x more undo levels
vim.o.updatetime     = 200
vim.o.confirm        = true                             -- Confirm to save changes before exiting modified buffer
vim.o.swapfile       = false                            -- bye bye

-- COMPLETING
vim.o.infercase      = true                             -- Infer letter cases for a richer built-in keyword completion
vim.opt.completeopt  = { 'menu', 'noselect', 'fuzzy' }  -- Options for built-in completion
vim.o.pumblend       = 0
vim.o.winblend       = 0
vim.o.pumheight      = 10                  -- Make popup menu smaller
vim.o.smartcase      = true                -- Don't ignore case with capitals
vim.o.wildmode       = "longest:full,full" -- Command-line completion mode
vim.o.pummaxwidth       = 100                        -- Limit maximum width of popup menu
vim.o.completefuzzycollect = 'keyword,files,whole_line' -- Use fuzzy matching when collecting candidates

-- FOLDING
vim.o.foldcolumn     = "0"
vim.o.foldenable     = true
vim.o.foldlevel      = 99
vim.o.foldmethod     = "expr"
vim.o.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
--
vim.opt.shortmess:append('WcC') -- Reduce command line messages
