--[[
    tobs_notify: this script's notifications go to tobs_notify when it runs, and the usual way when it doesn't.
    One file, loaded last among the shared scripts; nothing else in the script changes. It only touches this script's
    own calls: ox_lib's lib.notify, the ox_lib:notify / QBCore:Notify / esx:showNotification events, and
    exports.qbx_core:Notify. Copied from tobs_notify/shim/tobs_notify.lua (keep the copies the same).
]]

local function on()
    return GetResourceState('tobs_notify') == 'started'
end

-- Qbox's Notify(text, type, duration, subTitle): with a subtitle, the text is the title (as qbx_core shows it)
local function fromQbx(text, kind, duration, subTitle)
    if subTitle then return { title = text, text = subTitle, type = kind, duration = duration } end
    return { text = text, type = kind, duration = duration }
end

--- exports.<res>:<name> answered by fn in this script (the real export is still used for everything else)
local function wrapExport(res, name, fn)
    local mt = getmetatable(exports)
    if not mt or type(mt.__index) ~= 'function' then return end
    local real = mt.__index(exports, res)
    rawset(exports, res, setmetatable({}, {
        __index = function(_, key)
            if key == name then return fn end
            return real[key]
        end,
    }))
end

local NOTIFY_EVENTS = { ['ox_lib:notify'] = true, ['QBCore:Notify'] = true, ['esx:showNotification'] = true }

if IsDuplicityVersion() then
    -- server: notifications sent to players
    local triggerClient = TriggerClientEvent
    TriggerClientEvent = function(name, target, ...)
        if NOTIFY_EVENTS[name] and on() then return triggerClient('tobs_notify:notify', target, ...) end
        return triggerClient(name, target, ...)
    end

    local realQbx
    wrapExport('qbx_core', 'Notify', function(_, src, text, kind, duration, subTitle, ...)
        if on() then return triggerClient('tobs_notify:notify', src, fromQbx(text, kind, duration, subTitle)) end
        realQbx = realQbx or getmetatable(exports).__index(exports, 'qbx_core')
        return realQbx:Notify(src, text, kind, duration, subTitle, ...)
    end)
else
    -- client: notifications this script shows itself
    local trigger = TriggerEvent
    TriggerEvent = function(name, ...)
        if NOTIFY_EVENTS[name] and on() then return exports.tobs_notify:Notify(...) end
        return trigger(name, ...)
    end

    local realQbx
    wrapExport('qbx_core', 'Notify', function(_, text, kind, duration, subTitle, ...)
        if on() then return exports.tobs_notify:Notify(fromQbx(text, kind, duration, subTitle)) end
        realQbx = realQbx or getmetatable(exports).__index(exports, 'qbx_core')
        return realQbx:Notify(text, kind, duration, subTitle, ...)
    end)

    -- ox_lib: this script's own lib.notify (ox_lib may be loaded after this file: wrap it once everything has loaded)
    local function wrapLib()
        if type(lib) ~= 'table' or rawget(lib, '__tobsNotify') then return end
        local original = lib.notify
        lib.notify = function(data)
            if on() then return exports.tobs_notify:Notify(data) end
            return original(data)
        end
        rawset(lib, '__tobsNotify', true)
    end
    wrapLib()
    CreateThread(wrapLib)
end
