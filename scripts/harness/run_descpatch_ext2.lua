-- Diagnostic only (oslem7+ / KIO0 MX82): descriptor patch, force the +0x50
-- bit-0 test (03:279C) to accept, and treat request +0x0A bit 15 as clear in
-- the range check (03:2960, 03:2972) so the extent length is used.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x03279c,1,{fcw = fcw & ffbf; g}')
    m.debugger:command('bpset 0x032960,1,{fcw = fcw | 40; g}')
    m.debugger:command('bpset 0x032972,1,{fcw = fcw | 40; g}')
end)
dofile(HERE .. "run_descpatch.lua")
