local M = {}
local backend_process = nil

function M.start_backend(config)
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

return M
