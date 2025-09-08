

-- on start add plugins in install dir
local install_dir = '/usr/local/share/nvim/site/pack/core/opt'
local req = vim.uv.fs_scandir(install_dir)
if req then
  while true do
    local name, _ = vim.uv.fs_scandir_next(req)
    if not name then break end
    vim.cmd.packadd(name)
  end
end

