-- Inline image rendering via Ghostty's Kitty graphics protocol.
-- Opens PNG/JPG/etc. buffers as pictures and renders images embedded in
-- markdown/neorg/etc. inline. Needs the `magick` CLI for non-PNG/JPG formats.
return {
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = true },
    },
  },
}
