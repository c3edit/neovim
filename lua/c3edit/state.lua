local M = {}

M.currentlyCreatingDocument = nil
M.documentIdToBuffer = {}
M.bufferToDocumentId = {}
M.isEditing = false
-- TODO Support multiple peers.
M.documentIdToCursorExtmark = {}

return M
