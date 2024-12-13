local config = require('c3edit.config').defaults

local M = {}
local backend_process = nil

function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
end

function M.add_peer(ip_address)
    if not ip_address or ip_address == "" then
        print("Error: IP address is required.")
        return
    end

    send_message_to_backend("add_peer", {address = ip_address})
    print("Add peer message sent with address: " .. ip_address)
end

function M.start_backend()
    if not config.backend_path then
        print("Error: Backend path is not set. Please configure it using require('c3edit').setup().")
        return
    end

    backend_process = vim.fn.jobstart({config.backend_path}, {
        on_stdout = function(_, data)
            if data then
                print(table.concat(data, "\n"))
            end
        end,
        on_stderr = function(_, data)
            if data then
                print("Error: " .. table.concat(data, "\n"))
            end
        end,
        on_exit = function(_, code)
            print("Command exited with code " .. code)
        end,
        stdin = "pipe",
    })

    print("Backend started")
end

function M.send_bogus_data()
    send_message_to_backend("create_document", {name = "foo", initial_content = "data"})
end

function M.create_document()
    local current_file = vim.api.nvim_buf_get_name(0)
    local basename = vim.fn.fnamemodify(current_file, ":t")

    -- get current file contents
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")

    -- send message to backend
    send_message_to_backend("create_document", {name = basename, initial_content = content})
end

function send_message_to_backend(mtype, message)
    message.type = mtype
    local mjson = vim.fn.json_encode(message)
    
    vim.fn.chansend(backend_process, mjson .. "\n")
end

function handle_backend_output(data)
    local lines = vim.split(data, "\n")
    for _, line in ipairs(lines) do
        parse_backend_message(line)
    end
end

function parse_backend_message(data)
    local message = vim.fn.json_decode(data)
    if not message then
        print("Error: Could not parse JSON message")
        return
    end

    if message.type == "create_document_response" then
        print("Document created: " .. message.name)
    else
        print("Error: Unknown message type")
    end
end

return M
