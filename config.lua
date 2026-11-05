--[[
    tobs_notify: configuration
    Notifications drawn in light: a beam traces the outline, the inside fills, the words appear. Each kind has its own
    shape, so players know what kind it is before they read a word.
]]

Config = {}

--- The style for the whole server:
---   'island'   one message at a time, drawn in light at Config.Position
---   'badge'    no box: a small badge in the kind's shape round the icon, the words beside it
---   'stack'    full shapes stacked at Config.Position
---   'compact'  half height, title and text on one line, stacked at Config.Position
Config.Style = 'island'

--- Where the messages sit: 'middle-right', 'middle-left', 'top-right', 'top-left', 'top', 'bottom-right',
--- 'bottom-left', 'bottom'
Config.Position = 'middle-right'

Config.MaxVisible = 4           -- on screen at once ('island' shows one); the rest wait their turn
Config.Duration = 5000          -- ms a message stays when the script doesn't say (0 = until it is closed)
Config.Scale = 1.0              -- size: 1.2 bigger, 0.8 smaller (it scales with the screen height)
Config.DrawMs = 650             -- how long the light takes to draw the outline
Config.Reduced = false          -- true: no light drawing or motion, messages just appear
Config.HideInPauseMenu = true   -- hidden while the pause menu or the map is open

--- 'island' when nothing is showing: 'none' (nothing on screen), 'dot' (a small dark dot) or 'clock' (a small capsule
--- with the time)
Config.IslandIdle = 'none'

--- Icons: the four kinds have their own. A script may also send an icon name (ox_lib style, like 'car'): those are
--- Font Awesome icons, loaded from the internet when this is true.
Config.FontAwesome = true

--- The kinds. shape: 'soft' (rounded corners), 'notched' (notched sides), 'cut' (cut corners), 'round' (round ends).
--- sound: a GTA frontend sound { name, set }, or false. Add your own kinds the same way (a script sends type = 'police').
Config.Kinds = {
    success = { color = '#6ab04c', shape = 'soft', icon = 'check', sound = { name = 'CHECKPOINT_PERFECT', set = 'HUD_MINI_GAME_SOUNDSET' } },
    error = { color = '#ff6b7a', shape = 'notched', icon = 'cross', sound = { name = 'ERROR', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' } },
    warning = { color = '#f6b93b', shape = 'cut', icon = 'alert', sound = { name = 'Event_Message_Purple', set = 'GTAO_FM_Events_Soundset' } },
    info = { color = '#48a6ff', shape = 'round', icon = 'info', sound = false },
    -- police = { color = '#3b82f6', shape = 'cut', icon = 'shield-halved', sound = false },
}

--- Other names scripts use for the same kinds (ox_lib, QBCore, ESX)
Config.Aliases = {
    inform = 'info', primary = 'info', ['info'] = 'info', normal = 'info',
    warn = 'warning', danger = 'error', err = 'error', ok = 'success', good = 'success',
}

--- /notifytest shows every kind, a repeat, a long one and an update (only for players allowed command.notifytest)
Config.TestCommand = true
