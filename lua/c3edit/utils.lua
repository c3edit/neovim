local M = {}

function M.offset_to_row_col(buf, offset)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local current_offset = 0

    for row, line in ipairs(lines) do
        if current_offset + #line + 1 > offset then
            local col = offset - current_offset
            return row - 1, col
        end
        current_offset = current_offset + #line + 1
    end

    return nil, nil
end

return M
