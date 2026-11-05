--[[
    tobs_notify: client
    Notify(data) / Notify(text, type, duration, title) -> the screen (html/app.js draws it). Update(id, data), Close(id).
    No loop while nothing shows (module 1): the pause-menu check runs only while something is on screen or the island
    capsule is shown.
]]

local ready = false
local queued = {}           -- messages sent before the page was ready
local lastSound = {}        -- kind -> GetGameTimer() of its last sound (a burst of repeats plays one)
local showing = 0           -- messages on screen (the page reports it)

local function kindOf(value)
    if type(value) ~= 'string' then return 'info' end
    local k = value:lower()
    k = Config.Aliases[k] or k
    return Config.Kinds[k] and k or 'info'
end

local function clean(text, max)
    if text == nil then return nil end
    text = tostring(text)
    if #text > max then text = text:sub(1, max) end
    -- GTA colour codes (~r~, ~s~ ...) mean nothing here
    return (text:gsub('~%a~', ''))
end

--- One message from any of the shapes scripts use: a table (ox_lib: title, description, type, duration, icon, id),
--- or text, type, duration, title (QBCore / ESX). QBCore's table text { text = , caption = } works too.
local function normalise(a, b, c, d)
    local m
    if type(a) == 'table' then
        local text = a.text or a.description or a.message or a.msg or a.caption
        local title = a.title
        if type(a.text) == 'table' then
            -- QBCore: { text = 'Title', caption = 'the message' }
            if a.text.caption then title, text = a.text.text, a.text.caption else text = a.text.text end
        end
        m = { title = title, text = text, type = a.type or a.status, duration = a.duration or a.length or a.time, icon = a.icon, id = a.id }
    else
        m = { text = a, type = b, duration = c, title = d }
    end
    m.type = kindOf(m.type)
    m.title = clean(m.title, 80)
    m.text = clean(m.text, 400) or ''
    if m.title == '' then m.title = nil end
    if m.text == '' and not m.title then return nil end
    m.duration = tonumber(m.duration) or Config.Duration
    if m.duration < 0 then m.duration = Config.Duration end
    if type(m.icon) == 'table' then m.icon = m.icon[2] or m.icon[1] end
    m.icon = type(m.icon) == 'string' and m.icon:sub(1, 40) or nil
    m.id = m.id ~= nil and tostring(m.id):sub(1, 60) or nil
    return m
end

local function playSound(kind)
    local s = Config.Kinds[kind] and Config.Kinds[kind].sound
    if not s then return end
    local now = GetGameTimer()
    if lastSound[kind] and now - lastSound[kind] < 800 then return end
    lastSound[kind] = now
    PlaySoundFrontend(-1, s.name, s.set, true)
end

local function send(action, payload)
    if not ready then
        queued[#queued + 1] = { action = action, payload = payload }
        return
    end
    payload.action = action
    SendNUIMessage(payload)
end

--- Show a message. Returns its id (to update or close it later).
local function Notify(a, b, c, d)
    local m = normalise(a, b, c, d)
    if not m then return nil end
    m.idGiven = m.id ~= nil          -- the script will update / close it by this id
    m.id = m.id or ('n' .. GetGameTimer() .. math.random(1000, 9999))
    send('notify', { data = m })
    playSound(m.type)
    return m.id
end

local function Update(id, a, b, c, d)
    if id == nil then return end
    local m = normalise(a, b, c, d)
    if not m then return end
    m.id = tostring(id)
    send('update', { data = m })
end

local function Close(id)
    if id == nil then return end
    send('close', { id = tostring(id) })
end

exports('Notify', Notify)
exports('Update', Update)
exports('Close', Close)

-- from the server (exports.tobs_notify:Notify(source, ...)) or other resources
RegisterNetEvent('tobs_notify:notify', function(a, b, c, d) Notify(a, b, c, d) end)
RegisterNetEvent('tobs_notify:update', function(id, a, b, c, d) Update(id, a, b, c, d) end)
RegisterNetEvent('tobs_notify:close', function(id) Close(id) end)

-- the page is ready: it gets the config (styles, kinds), then what came before
RegisterNUICallback('ready', function(_, cb)
    cb({
        style = Config.Style, position = Config.Position, maxVisible = Config.MaxVisible, scale = Config.Scale,
        drawMs = Config.DrawMs, reduced = Config.Reduced, islandIdle = Config.IslandIdle,
        fontAwesome = Config.FontAwesome, kinds = Config.Kinds,
    })
    ready = true
    for _, q in ipairs(queued) do
        q.payload.action = q.action
        SendNUIMessage(q.payload)
    end
    queued = {}
end)

-- the page says how many are on screen: the pause-menu check only runs while that matters
local watching = false
local function watchPause()
    if watching or not Config.HideInPauseMenu then return end
    watching = true
    CreateThread(function()
        local hidden = false
        while showing > 0 or (Config.Style == 'island' and Config.IslandIdle ~= 'none') do
            local now = IsPauseMenuActive()
            if now ~= hidden then
                hidden = now
                SendNUIMessage({ action = 'hidden', hidden = now })
            end
            Wait(250)
        end
        if hidden then SendNUIMessage({ action = 'hidden', hidden = false }) end
        watching = false
    end)
end

RegisterNUICallback('count', function(data, cb)
    showing = tonumber(data and data.n) or 0
    if showing > 0 then watchPause() end
    cb(1)
end)

CreateThread(function()
    -- the island's idle capsule is always there: watch the pause menu for it from the start
    if Config.Style == 'island' and Config.IslandIdle ~= 'none' then watchPause() end
end)

-- /notifytest: every kind, a repeat, a long one and an update
if Config.TestCommand then
    -- the server registers the command (it checks command.notifytest) and sends this to the player who typed it
    RegisterNetEvent('tobs_notify:test', function() CreateThread(function()
        Notify({ title = 'Car stored', description = 'Krieger is in Legion Garage Parking', type = 'success' })
        Wait(900)
        Notify('You need $2,500 in the bank', 'error', 5000, 'Not enough money')
        Wait(900)
        Notify({ title = 'Wanted plate', description = '86TDE835 read at Legion Garage Plate reader', type = 'warning' })
        Wait(900)
        for _ = 1, 3 do
            Notify({ title = 'New message', description = 'Unknown number: "Meet at the pier"', type = 'inform' })
            Wait(250)
        end
        Wait(900)
        Notify({ description = 'A longer message without a title, to see how the shape grows with the words and wraps onto a second line when it has to.', type = 'info' })
        Wait(900)
        local id = Notify({ id = 'notifytest_progress', title = 'Uploading', description = 'Footage 0 %', type = 'info', duration = 0 })
        for p = 25, 100, 25 do
            Wait(800)
            Update(id, { title = 'Uploading', description = ('Footage %d %%'):format(p), type = p == 100 and 'success' or 'info', duration = 0 })
        end
        Wait(1500)
        Close(id)
        if Config.Kinds.police then
            Wait(600)
            Notify({ title = 'Dispatch', description = '10-31 in progress at Legion Square', type = 'police', icon = 'shield-halved' })
        end
    end) end)
end
