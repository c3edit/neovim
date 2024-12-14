local state = require('c3edit.state')
local utils = require('c3edit.utils')

local M = {}

function M.buf_on_bytes(_sig, buf, _tick, start_row, start_col, offset, old_end_row, old_end_col, old_end_len, new_end_row, new_end_col, new_end_len)
    if state.isEditing then
        return
    end
    
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

function M.on_cursor_moved()
    -- Cannot hoist due to circular dependency.
    local backend = require('c3edit.backend')
    
    local buf = vim.api.nvim_get_current_buf()
    local document_id = state.bufferToDocumentId[buf]
    if not document_id then
        print("Error: Received on_cursor_moved for unknown buffer ID: " .. buf)
        return
    end

    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" then
        -- Both row and column are one-indexed here!
        local _buf, row, col = unpack(vim.fn.getpos("."))
        local _buf, mark_row, mark_col = unpack(vim.fn.getpos("v"))

        local point = utils.row_col_to_offset(buf, row - 1, col - 1)
        local mark = utils.row_col_to_offset(buf, mark_row - 1, mark_col - 1)

        backend.send_message("set_selection", {
            document_id = document_id,
            point = point,
            mark = mark,
        })
    else
        -- Row is one-indexed here!
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local offset = utils.row_col_to_offset(buf, row - 1, col)
        backend.send_message("set_cursor", {
            document_id = document_id,
            location = offset,
        })
    end
end

return M
