local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x03266c,1,{printf "ENT  rr6=%04X:%04X ptr18=%04X:%04X\\n",r6,r7,dw@(r7+18),dw@(r7+1a); g}')
    m.debugger:command('bpset 0x0326b4,1,{printf "CHK  rr2=%04X:%04X dw=%04X db0=%02X db1=%02X\\n",r2,r3,dw@r3,db@r3,db@(r3+1); g}')
    m.debugger:command('bpset 0x0326b6,1,{printf "AFT  fcw=%04X\\n",fcw; g}')
    m.debugger:command('bpset 0x0326b8,1,{printf "C303 r1=%04X rr2=%04X:%04X\\n",r1,r2,r3; g}')
end)
dofile(HERE .. "run_descpatch.lua")
