local server = require "resty.websocket.server"
local rpc = require "util.rpc"

local wb, err = server:new{
    timeout = 10,  -- in milliseconds
    max_payload_len = 5242880, -- 5M
}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

local handler = rpc:new_handler(wb)
while true do 
    handler:heartbeat()

    local data, typ, err = wb:recv_frame()

    if not data then
        if not string.find(err, "timeout", 1, true) then
            ngx.log(ngx.ERR, "failed to receive a frame: ", err)
            return ngx.exit(444)
        end
    end

    if typ == "close" then
        -- for typ "close", err contains the status code
        local code = err

        -- send a close frame back:
        local bytes, err = wb:send_close(1000, "enough, enough!")
        if not bytes then
            ngx.log(ngx.ERR, "failed to send the close frame: ", err)
            return
        end
        ngx.log(ngx.INFO, "closing with status code ", code, " and message ", data)
        return
    end

    if typ == "ping" then
        -- send a pong frame back:
        local bytes, err = wb:send_pong(data)
        if not bytes then
            ngx.log(ngx.ERR, "failed to send frame: ", err)
            return
        end
    elseif typ == "binary" then
        local ret = handler:process(data)
        if not ret then
            return
        end
    elseif typ == "text" then
        -- echo for ping pong
        -- print("recv: ", data)
        local bytes, err = wb:send_text(data)
        if not bytes then
            ngx.log(ngx.ERR, "failed to send a text frame: ", err)
            return ngx.exit(444)
        end
    end
end

