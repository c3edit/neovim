local M = {}
local backend_process = nil

function M.greet()
    print("Hello from your plugin!")
end

function M.start_backend()
    backend_process = vim.fn.jobstart({"/home/ad/git/c3edit-backend/target/debug/c3edit"}, {
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

function send_message_to_backend(mtype, message)
    message.type = mtype
    local mjson = vim.fn.json_encode(message)
    
    vim.fn.chansend(backend_process, mjson .. "\n")
end

return M
