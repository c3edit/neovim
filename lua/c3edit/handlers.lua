local utils = require('c3edit.utils')

local M = {}
local documentIdToBuffer = {}
local currentlyCreatingDocument = nil

function M.handle_create_document_response(message)
    if not currentlyCreatingDocument then
        print("Error: Received create_document_response but no document is being created")
        return
    end

    documentIdToBuffer[message.id] = currentlyCreatingDocument
    currentlyCreatingDocument = nil

    print("Document created with ID: " .. message.id)
end

function M.handle_change(message)
    local document_id = message.document_id
    local buffer = documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received change for unknown document ID: " .. document_id)
        return
    end

    local change = message.change
    local row, col = utils.offset_to_row_col(buffer, change.index)

    if change.type == "insert" then
        vim.api.nvim_buf_set_text(buffer, row, col, row, col, {change.text})
    elseif change.type == "delete" then
        local end_row, end_col = utils.offset_to_row_col(buffer, change.index + change.len)
        vim.api.nvim_buf_set_text(buffer, row, col, end_row, end_col, {})
    else
        print("Error: Unknown change type: " .. change.type)
    end
end

function M.handle_set_cursor(message)
    local document_id = message.document_id
    local buffer = documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received set_cursor for unknown document ID: " .. document_id)
        return
    end

    local peer_id = message.peer_id
    if peer_id then
        print("Peer cursors are not yet supported. Ignoring peer_id: " .. peer_id)
    end

    if buffer ~= vim.api.nvim_get_current_buf() then
        print("Received set_cursor for a document that is not the current buffer!")
        return
    end
    
    local row, col = utils.offset_to_row_col(buffer, message.location)
    print("Setting cursor to row: " .. row .. ", col: " .. col)
    vim.api.nvim_win_set_cursor(0, {row + 1, col})
end

return M
