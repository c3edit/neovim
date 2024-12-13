vim.api.nvim_create_user_command('StartBackend', function()
    require('c3edit').start_backend()
end, {})

vim.api.nvim_create_user_command('SendBogusData', function()
    require('c3edit').send_bogus_data()
end, {})
