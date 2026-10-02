return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 15,
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = { border = "rounded" },
      start_in_insert = true,
      persist_size = true,
    })
  end,
  keymap = {
      { "t", "<Esc><Esc>", [[<C-\><C-n>]] }
  },
}
