local m = manager.machine
if os.getenv("ISL") == "floppy" then
    for _, f in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do f.user_value = 0 end
end
local base = os.getenv("OUT") .. "/"
local out = assert(io.open(base .. "events.log", "w"))
local screen = assert(m.screens[":slot3:go252:screen"])
local last = 0
emu.register_frame_done(function()
    local t = emu.time()
    if t >= last + 5 then
        last = last + 5
        screen:snapshot(base .. string.format("s_%04d.png", last))
        out:write(string.format("shot t=%.1f\n", t)); out:flush()
    end
end)
