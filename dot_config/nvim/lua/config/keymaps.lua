-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("i", "kj", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Escape terminal mode" })
vim.keymap.set("t", "kj", [[<C-\><C-n>]], { desc = "Escape terminal mode" })
