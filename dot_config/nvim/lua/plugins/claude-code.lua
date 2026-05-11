return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = { provider = "snacks" },
      diff_opts = {
        layout = "vertical",
        open_in_new_tab = false,
      },
    },
    keys = {
      { "<leader>a", nil, desc = "AI" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude Code" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude continue" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude resume" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude add buffer" },
      { "<leader>aS", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude send selection" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude deny diff" },
    },
  },
}
