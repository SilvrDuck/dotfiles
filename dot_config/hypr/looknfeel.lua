-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 4,
    border_size = 1,
  },

  decoration = {
    border_part_of_window = false,
  },
})

-- Snappy animations, using Omarchy's "quick" curve.
hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "quick", style = "popin 87%" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "quick" })

-- Fully opaque windows, except a slightly translucent Alacritty.
o.window(".*", { opacity = "1 1" })
o.window("Alacritty", { opacity = "0.94 override 0.94 override" })
