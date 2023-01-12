require('telescope').setup {
  defaults = {
    file_ignore_patterns = { 
      "node_modules",
      "package-lock.json" 
    }
  }
}
