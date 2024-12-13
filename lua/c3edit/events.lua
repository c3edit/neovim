local M = {}

function M.buf_on_bytes(_sig, buf, _tick, start_row, start_col, offset, old_end_row, old_end_col, old_end_len, new_end_row, new_end_col, new_end_len)
    print("Buffer ID: " .. buf)
    print("Start Position: (" .. start_row .. ", " .. start_col .. ")")
    print("Offset: " .. offset)
    print("Old End Position: (" .. old_end_row .. ", " .. old_end_col .. ") with length " .. old_end_len)
    print("New End Position: (" .. new_end_row .. ", " .. new_end_col .. ") with length " .. new_end_len)
end

return M
