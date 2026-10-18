if not require("core.utils").is_vscode then
    require("core.shell").sync_env()
end

require("core.basic")
require("core.commands")
require("core.terminal")
require("core.ft")
require("core.keymap")
require("core.miscellaneous")
require("core.symbols")
