-- Straight ASCII ' is *not* paired — too common in French (j'ai, l'on, …).
-- Only typographic openers trigger a pair.
return {
  { "folke/twilight.nvim", cmd = { "Twilight", "TwilightEnable", "TwilightDisable" } },

  -- Disable LazyVim's default mini.pairs so the two pair plugins don't fight.
  { "nvim-mini/mini.pairs", enabled = false },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)
      local Rule = require("nvim-autopairs.rule")
      npairs.add_rules({
        Rule("«", "»"),
        Rule("‹", "›"),
        Rule("\u{201C}", "\u{201D}"), -- “ ”
        Rule("\u{2018}", "\u{2019}"), -- ‘ ’
        Rule("\u{201E}", "\u{201C}"), -- „ “
      })
    end,
  },
}
