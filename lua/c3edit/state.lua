local M = {}

M.currentlyCreatingDocument = nil
M.documentIdToBuffer = {}
M.bufferToDocumentId = {}
M.isEditing = false

return M
