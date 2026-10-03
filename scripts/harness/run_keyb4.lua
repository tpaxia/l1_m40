local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 77 then return end
    done = true
    m.debugger:command('bpset 0x210b9a,1,{printf "REQ t req=%04X dev=%04X fn=%04X addr=%04X%04X len=%04X devid=%04X\\n",r5,dw@(r5+4),dw@(dw@(r5+1a)+2),dw@(r5+6a),dw@(r5+6c),dw@(r5+52),dw@(dw@(r5+4)+0e); g}')
    m.debugger:command('bpset 0x210b9c,1,{printf "RET r0=%04X r1=%04X\\n",r0,r1; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch_ext2.lua")
