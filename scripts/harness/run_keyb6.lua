local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 77 then return end
    done = true
    m.debugger:command('bpset 0x2205ce,1,{printf "ATT1 ret r0=%04X r1=%04X fcw=%04X\\n",r0,r1,fcw; g}')
    m.debugger:command('bpset 0x2205d6,1,{printf "ATT2 ret r0=%04X\\n",r0; g}')
    m.debugger:command('bpset 0x03021c,1,{printf "LOCKWAIT rr2=%04X:%04X val=%04X dev=%04X\\n",r2,r3,dw@r3,r4; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch_ext2.lua")
