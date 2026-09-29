-- Personal bindings on top of Omarchy's defaults (list them all with
-- `omarchy menu keybindings --print`). Hyprland fires every binding on a key,
-- so each one here first clears whatever Omarchy put on it. Key strings must
-- match Omarchy's spelling exactly for the unbind to take.
local function bind(keys, description, dispatcher)
  hl.unbind(keys)
  o.bind(keys, description, dispatcher)
end

-- Applications
bind("SUPER + ALT + RETURN", "Tmux", "omarchy-launch-terminal tmux new")
bind("SUPER + SHIFT + B", "Browser", o.launch("firefox"))
bind("SUPER + SHIFT + ALT + B", "Browser (private)", o.launch("firefox --private"))
bind("SUPER + SHIFT + M", "Music", "launch-app-or-webapp spotify spotify Spotify https://open.spotify.com")
bind("SUPER + SHIFT + ALT + M", "Google Maps", { webapp = "https://www.google.com/maps" })
bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
bind("SUPER + SHIFT + G", "Telegram", "launch-app-or-webapp Telegram telegram Telegram https://web.telegram.org/a/")
bind("SUPER + SHIFT + ALT + G", "WhatsApp", "launch-app-or-webapp whatsapp whatsapp WhatsApp https://web.whatsapp.com/")
bind("SUPER + SHIFT + S", "Slack", "launch-app-or-webapp slack slack Slack https://app.slack.com/client")
bind("SUPER + SHIFT + ALT + S", "Steam", o.launch("steam"))
bind("SUPER + SHIFT + ALT + A", "Claude", "claude-desktop")
bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/calendar/u/0/r" })
bind("SUPER + SHIFT + E", "Email", { webapp = "https://mail.google.com/mail/" })
bind("SUPER + SHIFT + ALT + E", "Infomaniak", { webapp = "https://ksuite.infomaniak.com/all/mail/" })
bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
bind("SUPER + CTRL + ALT + SPACE", "Fleet capture", "fleet-prompt")

-- Keyboard chord mirrors for the hardware media keys.
bind("SUPER + CTRL + P", "Play/pause", "omarchy-shell media playPause")
bind("SUPER + CTRL + bracketleft", "Previous track", "omarchy-shell media previous")
bind("SUPER + CTRL + bracketright", "Next track", "omarchy-shell media next")

-- Vi-style focus and swap. SUPER + J/K/L are Omarchy defaults, so the
-- keybindings menu moves to SUPER + CTRL + K and split toggling to SUPER + /.
bind("SUPER + H", "Move focus left", hl.dsp.focus({ direction = "l" }))
bind("SUPER + J", "Move focus down", hl.dsp.focus({ direction = "d" }))
bind("SUPER + K", "Move focus up", hl.dsp.focus({ direction = "u" }))
bind("SUPER + L", "Move focus right", hl.dsp.focus({ direction = "r" }))
bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")

-- Maximize on SUPER + ; and toggle split on SUPER + /, mirroring AeroSpace's
-- alt-; and alt-/ on macOS. Monitor scaling (Omarchy's SUPER + [ALT +] /) has
-- no macOS equivalent and is dropped.
hl.unbind("SUPER + F")
hl.unbind("SUPER + ALT + SLASH")
bind("SUPER + semicolon", "Maximize (fill workspace)", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + SLASH", "Toggle window split", hl.dsp.layout("togglesplit"))
