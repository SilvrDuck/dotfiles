-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Omarchy defaults (don't edit these directly).
require("default.hypr.omarchy")

-- Personal overrides, loaded after the defaults. monitors and autostart are
-- machine-local files created by the Omarchy installer; the rest are tracked.
require("hypr.monitors")
require("hypr.workspaces")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Omarchy floats every Steam window; tile the main library window instead.
o.window({ class = "steam", title = "Steam" }, { tile = true })
