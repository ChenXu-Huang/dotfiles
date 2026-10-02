local core_dir = vim.fn.stdpath("config") .. "/lua/core"

for _, file in ipairs(vim.fn.readdir(core_dir)) do
  if file:match("%.lua$") and file ~= "init.lua" then
    local module = "core." .. file:gsub("%.lua$", "")
    local ok, err = pcall(require, module)
    if not ok then
      vim.notify(
          "Failed to load module " .. module .. ": " .. err,
          vim.log.levels.ERROR,
          { title = "core loader" }
      )
    end
  end
end
