-- Explorer filtering — VS Code-ish:
--   hidden=true   show dotfiles (.env, .claude, …)
--   ignored=true  show .gitignored, but dimmed via SnacksPickerPathIgnored
--   exclude       hard-hide opaque caches only — build outputs, deps, and
--                 virtualenvs stay visible so devs can inspect them
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          exclude = {
            -- VCS + OS noise
            "**/.git", "**/.svn", "**/.hg", "**/.DS_Store", "**/Thumbs.db",

            -- Python tool caches
            "**/__pycache__", "**/.pytest_cache", "**/.mypy_cache",
            "**/.ruff_cache", "**/.tox", "**/.nox", "**/.hypothesis",
            "**/.pytype", "**/.ipynb_checkpoints", "**/.eggs",

            -- JS/TS bundler & package-manager caches
            "**/.cache", "**/.parcel-cache", "**/.vite", "**/.next/cache",
            "**/.npm", "**/.nyc_output",

            -- Coverage HTML output
            "**/htmlcov",

            -- Build-tool caches
            "**/.gradle", "**/.zig-cache", "**/CMakeFiles",

            -- Doc/serverless generator caches
            "**/.docusaurus", "**/.serverless",
          },
        },
      },
    },
  },
}
