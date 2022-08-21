
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.colorcolumn = '80'
vim.opt.cmdheight = 1

vim.opt.syntax = on
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true

vim.g.mapleader = ' '
vim.keymap.set('n', '<Leader>ff', '<CMD>Telescope find_files<CR>')
vim.keymap.set('n', '<Leader>gf', '<CMD>Telescope grep_string<CR>')
vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true } )
vim.keymap.set('n', 'gi', '<Plug>(coc-implementation)', { silent = true } )
vim.keymap.set('n', 'gr', '<Plug>(coc-references)', { silent = true } )

vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.coc_global_extensions = {
  'coc-angular',
  'coc-css',
  'coc-eslint',
  'coc-html',
  'coc-json',
  'coc-tsserver',
} 

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use 'gruvbox-community/gruvbox'
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-treesitter/nvim-treesitter'
  use {'neoclide/coc.nvim', branch = 'release', run = 'yarn install --frozen-lockfile'}

  require('telescope').setup {
    defaults = {
      file_ignore_patterns = { 
        "node_modules" 
      }
    }
  }

  require('nvim-treesitter.configs').setup { 
    ensure_installed = {
      'css',
      'dockerfile',
      'gitignore',
      'html',
      'json',
      'lua',
      'markdown',
      'scss',
      'typescript',
    },
    highlight = { 
      enable = true,
      additional_vim_regex_highlighting = false
    } 
  }
  vim.cmd('colorscheme gruvbox')
end)

