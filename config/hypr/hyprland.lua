-- Hyprland configuration entry point.
-- The modules are intentionally ordered: environment and core settings are
-- registered before rules, bindings and startup services.

require("modules.environment")
require("modules.appearance")
require("modules.input")
require("modules.rules")
require("modules.bindings")
require("modules.autostart")
