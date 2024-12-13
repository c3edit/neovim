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
    vim.fn.chansend(backend_process, "bogus data\n")
end

return M
