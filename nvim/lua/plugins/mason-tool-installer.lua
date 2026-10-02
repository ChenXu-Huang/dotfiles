return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    opts = {
        ensure_installed = {
            "pyright",
            "ruff",
        },
        auto_update = true,
        debounce_hours = 24,
        start_delay = 3000,
    },
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
    },
}
