local config = {}

config.defaults = {
    backend_path = nil
}

config.setup = function(user_config)
    config.config = vim.tbl_deep_extend("force", config.defaults, user_config or {})
end

return config
