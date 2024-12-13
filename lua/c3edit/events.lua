local state = require('c3edit.state')

local M = {}

function M.buf_on_bytes(_sig, buf, _tick, start_row, start_col, offset, old_end_row, old_end_col, old_end_len, new_end_row, new_end_col, new_end_len)
    -- Cannot hoist due to circular dependency.
    local backend = require('c3edit.backend')
    
    local document_id = state.bufferToDocumentId[buf]
    if not document_id then
        print("Error: Received on_bytes for unknown buffer ID: " .. buf)
        return
    end

    if old_end_len == 0 then
        local new_text = vim.api.nvim_buf_get_text(
            buf,
            start_row,
            start_col,
            start_row + new_end_row,
            start_col + new_end_col,
            {}
        )
        backend.send_message("change", {
            document_id = document_id,
            change = {
                type = "insert",
                index = offset,
                text = table.concat(new_text, "\n"),
            }
        })
    elseif new_end_len == 0 then
        backend.send_message("change", {
            document_id = document_id,
            change = {
                type = "delete",
                index = offset,
                len = old_end_len,
            }
        })
    else
        print("Error: Unknown on_bytes operation")
    end
end

return M
