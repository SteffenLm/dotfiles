
local capabilities = require('cmp_nvim_lsp').default_capabilities(
  vim.lsp.protocol.make_client_capabilities()
);

require('lspconfig').tsserver.setup{
  capabilities = capabilities,
  on_attach = function()
    -- buffer = 0 means only for the current buffer;
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, {buffer = 0});
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {buffer = 0});
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer = 0});
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, {buffer = 0});
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {buffer = 0});
    vim.keymap.set('n', '<Leader>ch', vim.lsp.buf.code_action, {buffer = 0});
    vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, {buffer = 0});
    vim.keymap.set('n', '<Leader>dp', vim.diagnostic.goto_prev, {buffer = 0});
    vim.keymap.set('n', '<Leader>dn', vim.diagnostic.goto_next, {buffer = 0});
    vim.keymap.set('n', '<Leader>dl', '<CMD>Telescope diagnostics<CR>');
  end,
}

