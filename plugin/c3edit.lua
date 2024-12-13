vim.api.nvim_create_user_command('StartBackend', function()
    require('c3edit').start_backend()
end, {})

vim.api.nvim_create_user_command('SendBogusData', function()
    require('c3edit').send_bogus_data()
end, {})

vim.api.nvim_create_user_command('CreateDocument', function()
    require('c3edit').create_document()
end, {})

vim.api.nvim_create_user_command('AddPeer', function(opts)
    require('c3edit').add_peer(opts.args)
end, { nargs = 1 })
