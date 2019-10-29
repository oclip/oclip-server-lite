local _M = {}

function _M.read_file(file_name)
    local f = io.open(file_name, "rb")
    if not f then
        return ""
    end

    local content = f:read("*all")
    f:close()
    return content
end

function _M.write_file(file_name, content, mode)
    mode = mode or "wb"
    local f = assert(io.open(file_name, mode))
    f:write(content or "")
    f:close()
end

function _M.copy_file(src_file_name, target_file_name, mode)
    mode = mode or "wb"
    local content = _M.read_file(src_file_name)
    _M.write_file(target_file_name, content, mode)
end

return _M
