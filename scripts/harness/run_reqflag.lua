local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x030328,1,{printf "SRC rr6=%04X:%04X w0=%04X w2=%04X w4=%04X w6=%04X w8=%04X wa=%04X\\n",r6,r7,dw@r7,dw@(r7+2),dw@(r7+4),dw@(r7+6),dw@(r7+8),dw@(r7+a); g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch.lua")
