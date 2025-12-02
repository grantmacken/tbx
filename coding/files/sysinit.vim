
lua << EOF
-- Initialization =============================================================
--Enable the built-in Lua module loader
vim.loader.enable()
  -- vim.deprecate = function() end

-- disable built-in providers
local providers = { "node", "perl", "ruby", "python", "python3" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

-- disable built-in plugins
local plugins = { 'gzip', 'netrwPlugin', 'rplugin', 'tarPlugin', 'tohtml', 'tutor', 'zipPlugin', }
for _, plugin in ipairs(plugins) do
  vim.g["loaded_" .. plugin] = 1
end

EOF
