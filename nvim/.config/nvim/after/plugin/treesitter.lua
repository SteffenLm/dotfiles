require('nvim-treesitter.configs').setup { 
  ensure_installed = {
    'css',
    'dockerfile',
    'gitignore',
    'html',
    'json',
    'javascript',
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
