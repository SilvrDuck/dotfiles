return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    keys = {
      { "<leader>ao", function() require("opencode").toggle() end, desc = "OpenCode" },
      { "<leader>aO", function() require("opencode").ask() end, desc = "OpenCode ask" },
      { "<leader>aV", function() require("opencode").ask("@selection: ") end, mode = "v", desc = "OpenCode send selection" },
    },
    opts = {},
  },
}
