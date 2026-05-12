-- markdownlint-cli2 doesn't walk past project roots to find config, so it
-- never sees our global ~/.markdownlint-cli2.yaml. Point it there explicitly.
return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters = opts.linters or {}
      opts.linters["markdownlint-cli2"] = {
        args = { "--config", vim.fn.expand("~/.markdownlint-cli2.yaml") },
      }
    end,
  },
}
