local c3edit = require('c3edit')

vim.api.nvim_create_user_command('StartBackend', c3edit.start_backend, {})

vim.api.nvim_create_user_command('CreateDocument', c3edit.create_document, {})

vim.api.nvim_create_user_command('AddPeer', c3edit.add_peer, { nargs = 1 })
