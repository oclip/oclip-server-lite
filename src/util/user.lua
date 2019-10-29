local uids = require "uids"
local M = {}

function M.get_uid(token)
    return uids[token]
end

return M
