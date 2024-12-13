local backend = require('c3edit.backend')
local state = require('c3edit.state')
local config = require('c3edit.config').config

local M = {}

function M.start_backend()
    if not config.backend_path then
        print("Error: Backend path is not set. Please configure it using require('c3edit').setup().")
        return
    end

    backend.start_backend(config)
end

function M.create_document()
    local current_file = vim.api.nvim_buf_get_name(0)
    local basename = vim.fn.fnamemodify(current_file, ":t")

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")

    backend.send_message("create_document", {name = basename, initial_content = content})
    state.currentlyCreatingDocument = vim.api.nvim_get_current_buf()
end

function M.add_peer(opts)
    local ip_address = opts.args
    if not ip_address or ip_address == "" then
        print("Error: IP address is required.")
        return
    end

    backend.send_message("add_peer", {address = ip_address})
    print("Add peer message sent with address: " .. ip_address)
end

return M
