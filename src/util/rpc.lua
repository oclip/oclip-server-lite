local cfg = require "config"
local file = require "util.file"
local user = require "util.user"
local msgpack = require "MessagePack"
msgpack.set_array "always_as_map"

local setmetatable = setmetatable
local pack = table.pack or pack
local unpack = table.unpack or unpack

local _M = {}

local mt = { __index = _M }

function _M.new_handler(self, wb)
    return setmetatable({
        wb = wb,
        authed = false,
        uid = nil,
        upload_filename = nil,
        vid = nil, -- data vesion id
    }, mt)
end

function _M.process(self, data)
    local proto = msgpack.unpack(data)
    local method = proto.method
    if not method then
        return self:close(512, "Protocol error.")
    end

    print("try method:", method, ":", #data)
    if not self.authed then
        if method ~= 'auth' then
            return self:close(500, "No authed.")
        end
    end
    local method_func = _M[method]
    if not method_func then
        return self:close(500, "No method.")
    end
    --ngx.log(ngx.ERR, "process: ", method, " : ", unpack(proto.params))

    local ret, res_method, res_params = method_func(self, unpack(proto.params))
    if not ret then
        return ret
    end

    if res_method then
        self:send(res_method, res_params)
    end
    return true
end

function _M.send(self, method, params)
    local proto = {
        method = method,
        params = params or {},
    }
    local data = msgpack.pack(proto)
    print("send:", method, #data)
    local bytes, err = self.wb:send_binary(data)
    if not bytes then
        ngx.log(ngx.ERR, "failed to send a binary frame: ", err)
        return ngx.exit(444)
    end
end

function _M.close(self, code, reason)
    self.wb:send_close(code, reason)
    return false
end

function _M.heartbeat(self)
    if not self.authed then
        --print("not authed")
        return
    end

    local clip_change = ngx.shared.clip_change
    local new_vid = clip_change:get(self.uid)
    if self.vid ~= new_vid then
        print("new_vid:", new_vid, ", old_vid:", self.vid)
        self.vid = new_vid
        -- push new data
        local content = file.read_file(self.upload_filename)
        self:send('paste', {content})
    end
end

----------------------------------
-- rpc function impletement
----------------------------------

function _M.auth(self, token)
    if not token then
        return self:close(500, "No token")
    end

    local uid = user.get_uid(token)
    if not uid then
        return self:close(500, "Auth failed.")
    end
    self.authed = true
    self.uid = uid
    self.upload_filename = string.format("%s/%s", cfg.upload_dir, uid)
    local clip_change = ngx.shared.clip_change
    self.vid = clip_change:get(uid)
    return true, 'auth'
end

function _M.copy(self, content)
    file.write_file(self.upload_filename, content)
    
    -- update data version id
    local clip_change = ngx.shared.clip_change
    local vid = clip_change:incr(self.uid, 1, 0)
    self.vid = vid
    return true
end

function _M.paste(self)
    local content = file.read_file(self.upload_filename)
    return true, 'paste', {content}
end

return _M

