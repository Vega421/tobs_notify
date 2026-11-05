# Changelog

All notable changes to tobs_notify.

## 1.0.0 · 2026-11-05

**The first version: notifications drawn in light, a shape per kind.**

- A beam of light traces each message's outline, the inside fills and the words appear; on the way out the beam
  runs off. `Config.DrawMs` sets the speed, `Config.Reduced` turns the motion off
- A shape per kind: success soft corners, error notched sides, warning cut corners, info round ends; custom kinds in
  `Config.Kinds`
- Four styles: `island` (one at a time; nothing, a dot or a small clock when idle), `badge` (a small badge, no box),
  `stack` and `compact`, in eight positions (default `middle-right`)
- Repeats counted (×2, ×3), a queue over `Config.MaxVisible`, update and close by id, a sound per kind
- Client and server exports that take ox_lib's fields or QBCore's arguments; Font Awesome icon names
- `shim/tobs_notify.lua`: one file that sends a script's ox_lib / Qbox / QBCore / ESX notifications to tobs_notify
- `/notifytest` and `/notifytest server`
- Optional: four lines in ox_lib that send every ox_lib / Qbox notification on the server to tobs_notify
