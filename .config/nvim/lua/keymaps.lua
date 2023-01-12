vim.g.mapleader = ' '
vim.keymap.set('n', '<Leader>pv', '<CMD>Ex<CR>')
vim.keymap.set('n', '<Leader>ff', '<CMD>Telescope find_files<CR>')
vim.keymap.set('n', '<Leader>gf', '<CMD>Telescope live_grep<CR>')

vim.keymap.set('n', '<Leader>ng', '<CMD>Neogit<CR>')
vim.keymap.set('n', '<Leader>bn', ':<C-u>call gitblame#echo()<CR>', { silent = true } )

vim.keymap.set('n', '<Leader>nt', ':tabnew %<CR>', { silent = true } )
vim.keymap.set('n', '<M-k>', ':tabnext<CR>', { silent = false } )
vim.keymap.set('n', '<M-j>', ':tabprevious<CR>', { silent = false } )

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
