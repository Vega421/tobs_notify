<div align="center">

# tobs_notify

**Notifications drawn in light. Every kind has its own shape, so players know what it is before they read a word.**

[![License](https://img.shields.io/github/license/Vega421/tobs_notify?style=flat-square)](LICENSE)

[**Download**](https://github.com/Vega421/tobs_notify/releases/latest) · [**Documentation**](https://vega421.github.io/scripts/tobs-notify/) · [Changelog](CHANGELOG.md) · [Report a problem](https://github.com/Vega421/tobs_notify/issues)

</div>

---

<p align="center"><img src="https://vega421.github.io/assets/store/tobs-notify.png" alt="The four styles in game: island, badge, stack and compact" width="560"></p>

A beam of light traces the outline, the inside fills, the words appear; when it's done, the beam runs off the far
end. Free, standalone, for any framework.

## The shapes

| Kind | Shape | Colour |
| --- | --- | --- |
| **success** | soft corners | green |
| **error** | notched sides | red |
| **warning** | cut corners | amber |
| **info** | round ends | blue |

Add your own kinds in `config.lua` (a colour, an icon and one of the four shapes).

## Four styles (pick one in `config.lua`)

| `Config.Style` | What it looks like |
| --- | --- |
| `island` | One message at a time, drawn in light; nothing on screen in between (or a dot or a small clock, if you want). |
| `badge` | No box at all: a small badge in the kind's shape round the icon, the words beside it. |
| `stack` | Full shapes stacked in a corner. |
| `compact` | Half the height: title and text on one line. |

Every style goes in any of eight positions (`Config.Position`, default `middle-right`).

## Also

- The same message again while it shows: one message with **×2, ×3**, not a wall of copies
- **Update and close by id:** a message that counts up ("Uploading 25 %… 100 %") and turns green when done
- A sound per kind (off for info), hidden in the pause menu, sizes that scale with the screen, a `Reduced` setting
  with no motion
- **0.00 ms** while nothing shows

## Install

1. Put `tobs_notify` in your resources and add `ensure tobs_notify` to `server.cfg`, after `ox_lib` if you use it.
2. Pick a style in `config.lua`.
3. Try it: `/notifytest`, and `/notifytest server` for the server export (players with the ace `command.notifytest`).

### Every ox_lib and Qbox notification (optional)

To have tobs_notify draw every notification on the server (qbx_core, the Qbox scripts, ox_inventory and anything else
that uses ox_lib), open `ox_lib/resource/interface/client/notify.lua`, find `function lib.notify(data)` and put
these lines straight under it:

```lua
    -- tobs_notify: while it runs, every ox_lib / Qbox notification is drawn by it (remove these 4 lines to undo)
    if GetResourceState('tobs_notify') == 'started' then
        return exports.tobs_notify:Notify(data)
    end
```

Restart the server. When tobs_notify isn't running, ox_lib draws its own as before. An ox_lib update replaces this
file, so add the lines again after updating.

## Use it from your script

```lua
-- client (the same fields as ox_lib's lib.notify)
exports.tobs_notify:Notify({ title = 'Car stored', description = 'Krieger is in Legion Garage Parking', type = 'success' })
exports.tobs_notify:Notify('You need $2,500 in the bank', 'error', 5000)        -- text, type, duration

-- server (-1 = everyone)
exports.tobs_notify:Notify(source, { title = 'Paid', description = '$250 fine', type = 'success' })

-- one that changes, then closes
local id = exports.tobs_notify:Notify({ id = 'upload', description = 'Uploading 0 %', type = 'info', duration = 0 })
exports.tobs_notify:Update(id, { description = 'Uploading 100 %', type = 'success', duration = 0 })
exports.tobs_notify:Close(id)
```

### Scripts that use ox_lib or Qbox notifications

Copy `shim/tobs_notify.lua` into the script and add one line at the end of its `fxmanifest.lua`:

```lua
shared_script 'tobs_notify.lua'
```

That script's `lib.notify`, `ox_lib:notify`, `QBCore:Notify`, `esx:showNotification` and `exports.qbx_core:Notify`
then show in tobs_notify, and the usual way when tobs_notify isn't running. Nothing else in the script changes.

## License

GPL-3.0. See [LICENSE](LICENSE).
