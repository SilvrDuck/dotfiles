return {
  "obsidian-nvim/obsidian.nvim",
  ft = "markdown",
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "main", path = "~/vaults/main" },
    },
    ui = { enable = false },  -- render-markdown.nvim handles visuals
  },
}
