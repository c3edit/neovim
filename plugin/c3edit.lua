vim.api.nvim_create_user_command('Greet', function()
    require('c3edit').greet()
end, {})

vim.api.nvim_create_user_command('StartBackend', function()
    require('c3edit').start_backend()
end, {})
