-- Configure Mason
local mason = require('mason')
local mason_lspconfig = require('mason-lspconfig')

-- Configure LSP for Angular and NX Workspaces
local lspconfig = require('lspconfig')
local util = require('lspconfig.util')

mason.setup();
-- mason_lspconfig.setup();

local capabilities = require('cmp_nvim_lsp').default_capabilities(
vim.lsp.protocol.make_client_capabilities()
);

local attach = function()
  -- buffer = 0 means only for the current buffer;
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, {buffer = 0});
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {buffer = 0});
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer = 0});
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, {buffer = 0});
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {buffer = 0});
  vim.keymap.set('n', 'pf', vim.lsp.buf.format, {buffer = 0});
  vim.keymap.set('n', '<Leader>ch', vim.lsp.buf.code_action, {buffer = 0});
  vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, {buffer = 0});
  vim.keymap.set('n', '<Leader>dp', vim.diagnostic.goto_prev, {buffer = 0});
  vim.keymap.set('n', '<Leader>dn', vim.diagnostic.goto_next, {buffer = 0});
  vim.keymap.set('n', '<Leader>dl', '<CMD>Telescope diagnostics<CR>');
end


mason_lspconfig.setup {
  ensure_installed = { "lua_ls", "pyright", "ts_ls" }, -- servers you want
  automatic_installation = true,
}

-- Instead of setup_handlers, loop over servers
for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
  lspconfig[server].setup {
      capabilities = capabilities,
      on_attach = attach
  }
end


lspconfig.angularls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = util.root_pattern('project.json', 'angular.json'),
}

