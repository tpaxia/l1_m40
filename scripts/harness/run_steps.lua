local m = manager.machine
if os.getenv("ISL") == "floppy" then for _, field in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do field.user_value = 0 end end
local base = os.getenv("OUT") .. "/"
local out = assert(io.open(base .. "events.log", "w"))
local screen = assert(m.screens[":slot3:go252:screen"])
local function field(port, name) local f = m.ioport.ports[port].fields[name]; assert(f, name); return f end
local kenter = field(":slot3:go252:keyboard:K5", "Keypad ENTER (61)")
local ctrl = field(":slot3:go252:keyboard:K3", "CONTROL (70/78)")
local shift = field(":slot3:go252:keyboard:K3", "SHIFT (6E/76)")
local lock = field(":slot3:go252:keyboard:K3", "LOCK (6F/77)")
local jkey = field(":slot3:go252:keyboard:K2", "j")
local events = {}
local function add(t, f, n) events[#events + 1] = {t, f, n} end
local function tap(t, f, n) add(t, function() f:set_value(1) end, n .. " down"); add(t + 0.3, function() f:set_value(0) end, n .. " up") end
-- STEPS: "t:text" types text; "t:<KE>" keypad enter; "t:<CJ>" ctrl+j
for t, k in (os.getenv("STEPS") or ""):gmatch("([%d.]+):([^;]*)") do
    t = tonumber(t)
    if k == "<KE>" then tap(t, kenter, "KENTER")
    elseif k == "<LK>" then tap(t, lock, "LOCK")
    elseif k == "<CJP>" then
        add(t, function() ctrl:set_value(1) end, "CTRL down")
        add(t + 0.3, function() jkey:set_value(1) end, "J down")
        add(t + 0.6, function() jkey:set_value(0) end, "J up")
        add(t + 0.9, function() ctrl:set_value(0) end, "CTRL up")
    elseif k == "<CJ>" then
        add(t, function() ctrl:set_value(1) end, "CTRL down")
        add(t + 0.2, function() m.natkeyboard:post("j") end, "j")
        add(t + 1.0, function() ctrl:set_value(0) end, "CTRL up")
    else add(t, function() m.natkeyboard:post(k) end, "type " .. k) end
end

for t = 60, tonumber(os.getenv("RUN_SECONDS") or "200"), 5 do
    add(t, function() screen:snapshot(base .. string.format("s_%04d.png", t)) end, "shot")
end
table.sort(events, function(a, b) return a[1] < b[1] end)
local n = 1
emu.register_frame_done(function()
    while n <= #events and emu.time() >= events[n][1] do
        events[n][2](); out:write(string.format("EVENT t=%.3f %s\n", emu.time(), events[n][3])); out:flush(); n = n + 1
    end
end)
