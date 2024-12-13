local commands = require('c3edit.commands')

vim.api.nvim_create_user_command('StartBackend', commands.start_backend, {})
vim.api.nvim_create_user_command('CreateDocument', commands.create_document, {})
vim.api.nvim_create_user_command('AddPeer', commands.add_peer, { nargs = 1 })
