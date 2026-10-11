-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    -- EurKEY: US layout with European letters/symbols on AltGr.
    kb_layout = "eu",
    -- Replaces Omarchy's compose:caps so Caps Lock stays a Caps Lock.
    -- nbsp:level3 puts a non-breaking space on AltGr+Space, matching
    -- EurKEY Next's Option+Space on macOS.
    kb_options = "nbsp:level3",
    repeat_delay = 600,
  },
})
