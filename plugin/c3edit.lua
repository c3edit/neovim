vim.api.nvim_create_user_command('Greet', function()
    require('c3edit').greet()
end, {})
