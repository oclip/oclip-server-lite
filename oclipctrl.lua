#!/usr/bin/env lua

local function usage()
    print([[
oclipctrl --list           list uids with token
oclipctrl --add <uid>      add one uid
oclipctrl --del <uid>      del one uid]])
end

local uids_filepath = "/data/oclip_src/uids.lua"
local function read_uids()
    return dofile(uids_filepath)
end

local uids_content = [[
return {
%s
}
]]
local function write_uids(uids)
    local fd = io.open(uids_filepath, "w")
    if not fd then
        return false
    end

    local uids_list = {}
    for token, uid in pairs(uids) do
        local uid_str = string.format('    ["%s"] = "%s",', token, uid)
        table.insert(uids_list, uid_str)
    end
    local uids_list_str = table.concat(uids_list, "\n")
    local content = string.format(uids_content, uids_list_str)

    fd:write(content)
    fd:flush()
    fd:close()
    return true
end

local random = math.random
local function uuid()
    math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function add(uid)
    local uids = read_uids()
    local token = uuid()
    uids[token] = uid
    write_uids(uids)
    print(string.format("Add Success. uid: %s , token: %s", uid, token))
end

local function del(uid)
    local uids = read_uids()
    for token, _uid in pairs(uids) do
        if uid == _uid then
            uids[token] = nil
            print(string.format("Del Success. uid: %s , token: %s", uid, token))
        end
    end
    write_uids(uids)
end

local function list()
    local uids = read_uids()
    for token,uid in pairs(uids) do
        print(string.format("uid: %s , token: %s", uid, token))
    end
end

local cmd = arg[1]
if cmd == "--list" then
    list()
elseif cmd == "--add" then
    local uid = arg[2]
    if not uid or #uid == 0 then
        print("Need uid")
        os.exit(1)
    end
    add(uid)
elseif cmd == "--del" then
    local uid = arg[2]
    if not uid or #uid == 0 then
        print("Need uid")
        os.exit(1)
    end
    del(uid)
else
    usage()
end

