-- Diagnostic only: descriptor patch (run_descpatch.lua) plus, in KIO0 MX82,
-- force the "+0x50 bit 0" test at 03:279C to the accept path by clearing Z.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x03279c,1,{fcw = fcw & ffbf; g}')
end)
dofile(HERE .. "run_descpatch.lua")
