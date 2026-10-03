local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x03279c,1,{fcw = fcw & ffbf; g}')
    m.debugger:command('bpset 0x03296a,1,{printf "RNG r7=%04X addr=%04X%04X limit=%04X%04X x62=%04X%04X x66=%04X%04X x84=%04X x0a=%04X\\n",r7,r0,r1,r2,r3,dw@(r7+62),dw@(r7+64),dw@(r7+66),dw@(r7+68),dw@(r7+84),dw@(r7+0a); g}')
end)
dofile(HERE .. "run_descpatch.lua")
