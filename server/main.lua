--[[
    tobs_notify: server
    exports.tobs_notify:Notify(source, data) or Notify(source, text, type, duration, title); source -1 = everyone.
    Update(source, id, data) and Close(source, id) for messages shown with an id.
]]

local function target(src)
    src = tonumber(src)
    if not src then return nil end
    if src == -1 then return -1 end
    if src < 1 or GetPlayerName(src) == nil then return nil end
    return src
end

exports('Notify', function(src, a, b, c, d)
    local t = target(src)
    if not t then return false end
    TriggerClientEvent('tobs_notify:notify', t, a, b, c, d)
    return true
end)

exports('Update', function(src, id, a, b, c, d)
    local t = target(src)
    if not t then return false end
    TriggerClientEvent('tobs_notify:update', t, id, a, b, c, d)
    return true
end)

exports('Close', function(src, id)
    local t = target(src)
    if not t then return false end
    TriggerClientEvent('tobs_notify:close', t, id)
    return true
end)

-- /notifytest (players allowed command.notifytest, group.admin has it): the client shows the test
-- /notifytest server: two messages sent through the server export (ox_lib fields, then QBCore arguments)
-- /notifytest slow: each kind alone for 20 s; /notifytest all: the four kinds at once for 20 s (resmon)
-- /notifytest style <island|badge|stack|compact>: switch the style live (until a restart), the four kinds for 20 s
-- /notifytest styles: one message in each of the four styles at once for 20 s (a picture of them all)
if Config.TestCommand then
    RegisterCommand('notifytest', function(src, args)
        if src <= 0 then return end
        if args[1] == 'server' then
            exports.tobs_notify:Notify(src, { title = 'Server test', description = 'Sent with the server export (ox_lib fields)', type = 'inform' })
            SetTimeout(1200, function()
                exports.tobs_notify:Notify(src, 'Sent with the server export (QBCore arguments)', 'success', 5000, 'Server test')
            end)
            return
        end
        if args[1] == 'styles' then
            TriggerClientEvent('tobs_notify:test', src, 'styles')
            return
        end
        if args[1] == 'style' then
            local style = args[2] or Config.Style
            if style ~= 'island' and style ~= 'badge' and style ~= 'stack' and style ~= 'compact' then
                exports.tobs_notify:Notify(src, { title = '/notifytest style', description = 'island, badge, stack or compact', type = 'error' })
                return
            end
            TriggerClientEvent('tobs_notify:test', src, 'style', style)
            return
        end
        -- 'slow': each kind alone for 20 s (screenshots, video); 'all': the four at once for 20 s (resmon)
        local mode = (args[1] == 'slow' or args[1] == 'all') and args[1] or nil
        TriggerClientEvent('tobs_notify:test', src, mode)
    end, true)
end
