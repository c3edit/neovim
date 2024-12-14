local utils = require('c3edit.utils')
local state = require('c3edit.state')
local events = require('c3edit.events')

local M = {}

function M.add_peer_response(message)
    print("Added peer at address: " .. message.address)
end

function M.create_document_response(message)
    if not state.currentlyCreatingDocument then
        print("Error: Received create_document_response but no document is being created")
        return
    end

    state.documentIdToBuffer[message.id] = state.currentlyCreatingDocument
    state.bufferToDocumentId[state.currentlyCreatingDocument] = message.id
    vim.api.nvim_buf_attach(state.currentlyCreatingDocument, false, {
        on_bytes = events.buf_on_bytes
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = state.currentlyCreatingDocument,
        callback = events.on_cursor_moved,
    })
    vim.api.nvim_create_autocmd("CursorMovedI", {
        buffer = state.currentlyCreatingDocument,
        callback = events.on_cursor_moved,
    })
    vim.api.nvim_create_autocmd("ModeChanged", {
        -- Reuse `on_cursor_moved` to update the cursor appearance (will add/remove
        -- selection as appropriate).
        pattern = {"*:v", "v:*"},
        callback = events.on_cursor_moved,
    })

    state.currentlyCreatingDocument = nil

    print("Document created with ID: " .. message.id)
end

function M.change(message)
    local document_id = message.document_id
    local buffer = state.documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received change for unknown document ID: " .. document_id)
        return
    end

    local change = message.change
    local row, col = utils.offset_to_row_col(buffer, change.index)

    state.isEditing = true
    if change.type == "insert" then
        vim.api.nvim_buf_set_text(buffer, row, col, row, col, {change.text})
    elseif change.type == "delete" then
        local end_row, end_col = utils.offset_to_row_col(buffer, change.index + change.len)
        vim.api.nvim_buf_set_text(buffer, row, col, end_row, end_col, {})
    else
        print("Error: Unknown change type: " .. change.type)
    end
    state.isEditing = false
end

function M.set_cursor(message)
    local document_id = message.document_id
    local buffer = state.documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received set_cursor for unknown document ID: " .. document_id)
        return
    end

    local peer_id = message.peer_id
    if peer_id then
        print("Received set_cursor for peer ID: " .. peer_id)

        -- TODO Move somewhere appropriate.
        vim.api.nvim_set_hl(
            vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"),
            "PeerCursor",
            {bg = "red"}
        )
        vim.api.nvim_set_hl_ns(vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"))
        
        -- TODO Support multiple peers.
        local cursor_extmark = state.documentIdToCursorExtmark[document_id]
        local row, col = utils.offset_to_row_col(buffer, message.location)

        cursor_extmark = vim.api.nvim_buf_set_extmark(
            buffer,
            vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"),
            row, col,
            {
                id = cursor_extmark,
                end_line = row,
                end_col = col + 1,
                hl_group = "PeerCursor",
            }
        )

        state.documentIdToCursorExtmark[document_id] = cursor_extmark
                
        return
    end

    if buffer ~= vim.api.nvim_get_current_buf() then
        print("Received set_cursor for a document that is not the current buffer!")
        return
    end
    
    local row, col = utils.offset_to_row_col(buffer, message.location)
    print("Setting cursor to row: " .. row .. ", col: " .. col)
    vim.api.nvim_win_set_cursor(0, {row + 1, col})
end

function M.set_selection(message)
    local document_id = message.document_id
    local buffer = state.documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received set_selection for unknown document ID: " .. document_id)
        return
    end

    local peer_id = message.peer_id
    if peer_id then
        print("Received set_selection for peer ID: " .. peer_id)

        -- TODO Move somewhere appropriate.
        vim.api.nvim_set_hl(
            vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"),
            "PeerCursor",
            {bg = "red"}
        )
        vim.api.nvim_set_hl_ns(vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"))
        
        -- TODO Support multiple peers.
        local cursor_extmark = state.documentIdToCursorExtmark[document_id]
        local start_row, start_col
        local end_row, end_col

        if message.point < message.mark then
            start_row, start_col = utils.offset_to_row_col(buffer, message.point)
            end_row, end_col = utils.offset_to_row_col(buffer, message.mark)
        else
            start_row, start_col = utils.offset_to_row_col(buffer, message.mark)
            end_row, end_col = utils.offset_to_row_col(buffer, message.point)
        end

        cursor_extmark = vim.api.nvim_buf_set_extmark(
            buffer,
            vim.api.nvim_create_namespace("c3edit_peer_cursor_ns"),
            start_row, start_col,
            {
                id = cursor_extmark,
                end_line = end_row,
                end_col = end_col,
                hl_group = "PeerCursor",
            }
        )

        state.documentIdToCursorExtmark[document_id] = cursor_extmark
        
        return
    end

    print("Error: set_selection for self not yet implemented")
end

return M
