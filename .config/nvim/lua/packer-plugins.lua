require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use { "catppuccin/nvim", as = "catppuccin" }
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-treesitter/nvim-treesitter'
  use 'zivyangll/git-blame.vim'
  -- use {'neoclide/coc.nvim', branch = 'release', run = 'yarn install --frozen-lockfile'}
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP
  use 'hrsh7th/nvim-cmp' -- autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- lsp autocompletion
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'

  use {'prettier/vim-prettier', run = 'yarn install --frozen-lockfile'}
  use {
    'TimUntersberger/neogit',
    requires = {
      'nvim-lua/plenary.nvim',
    }
  }
end)
