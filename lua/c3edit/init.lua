local config = require('c3edit.config').defaults
local utils = require('c3edit.utils')
local backend = require('c3edit.backend')

local M = {}
local currentlyCreatingDocument = nil
local documentIdToBuffer = {}

function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
end

function M.add_peer(opts)
    local ip_address = opts.args
    if not ip_address or ip_address == "" then
        print("Error: IP address is required.")
        return
    end

    backend.send_message("add_peer", {address = ip_address})
    print("Add peer message sent with address: " .. ip_address)
end

function M.start_backend()
    if not config.backend_path then
        print("Error: Backend path is not set. Please configure it using require('c3edit').setup().")
        return
    end

    backend.start_backend(config)
end

function M.create_document()
    local current_file = vim.api.nvim_buf_get_name(0)
    local basename = vim.fn.fnamemodify(current_file, ":t")

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")

    backend.send_message("create_document", {name = basename, initial_content = content})
    currentlyCreatingDocument = vim.api.nvim_get_current_buf()
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

    if message.type == "create_document_response" then
        handle_create_document_response(message)
    elseif message.type == "change" then
        handle_change(message)
    elseif message.type == "set_cursor" then
        handle_set_cursor(message)
    else
        print("Error: Unknown message: " .. data)
    end
end

function handle_create_document_response(message)
    if not currentlyCreatingDocument then
        print("Error: Received create_document_response but no document is being created")
        return
    end

    documentIdToBuffer[message.id] = currentlyCreatingDocument
    currentlyCreatingDocument = nil

    print("Document created with ID: " .. message.id)
end

function handle_change(message)
    local document_id = message.document_id
    local buffer = documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received change for unknown document ID: " .. document_id)
        return
    end

    local change = message.change
    local row, col = utils.offset_to_row_col(buffer, change.index)

    if change.type == "insert" then
        -- TODO fix multi-line text (split by newline character, I think)
        vim.api.nvim_buf_set_text(buffer, row, col, row, col, {change.text})
    elseif change.type == "delete" then
        local end_row, end_col = utils.offset_to_row_col(buffer, change.index + change.len)
        vim.api.nvim_buf_set_text(buffer, row, col, end_row, end_col, {})
    else
        print("Error: Unknown change type: " .. change.type)
    end
end

function handle_set_cursor(message)
    local document_id = message.document_id
    local buffer = documentIdToBuffer[document_id]
    if not buffer then
        print("Error: Received set_cursor for unknown document ID: " .. document_id)
        return
    end

    local peer_id = message.peer_id
    if peer_id then
        -- TODO Implement peer cursors
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
