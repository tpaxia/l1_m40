local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x210b9c,1,{printf "RET  t r0=%04X r1=%04X\\n",r0,r1; g}')
    m.debugger:command('bpset 0x0326b8,1,{printf "C303 pc=%06X r1(fn)=%04X rr2=%04X:%04X rr6=%04X:%04X blk18w=%04X\\n",pc,r1,r2,r3,r6,r7,dw@(dw@(r7+1a)+2); g}')
    m.debugger:command('bpset 0x0326b4,1,{printf "CHK  r1=%04X word=%04X\\n",r1,dw@r3; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch.lua")
