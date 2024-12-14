local handlers = require('c3edit.handlers')

local M = {}
local backend_process = nil

function M.start_backend()
    local config = require('c3edit.config').config
    
    if not config.backend_path then
        print("Error: Backend path is not set. Please configure it using require('c3edit').setup().")
        return
    end

    backend_process = vim.fn.jobstart({config.backend_path}, {
        on_stdout = handle_backend_output,
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

function M.send_message(mtype, message)
    message.type = mtype
    local mjson = vim.fn.json_encode(message)
    vim.fn.chansend(backend_process, mjson .. "\n")
end

function handle_backend_output(_handle, data)
    -- TODO The API says that the data can include incomplete lines due to the
    -- OS. However, the backend always flushes entire lines to output, so do we
    -- actually have to handle that?
    for _, line in ipairs(data) do
        if line ~= "" then
            parse_backend_message(line)
        end        
    end
end

function parse_backend_message(data)
    local message = vim.fn.json_decode(data)
    if not message then
        print("Error: Could not parse JSON message")
        return
    end

    if message.type == "add_peer_response" then
        handlers.add_peer_response(message)
    elseif message.type == "create_document_response" then
        handlers.create_document_response(message)
    elseif message.type == "change" then
        handlers.change(message)
    elseif message.type == "set_cursor" then
        handlers.set_cursor(message)
    elseif message.type == "set_selection" then
        handlers.set_selection(message)
    else
        print("Error: Unknown message: " .. data)
    end
end

return M
