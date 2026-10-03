local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x03279c,1,{printf "F279C fcw=%04X\\n",fcw; fcw = fcw & ffbf; g}')
    m.debugger:command('bpset 0x0326b8,1,{printf "C303 r1=%04X\\n",r1; g}')
    m.debugger:command('bpset 0x0327ae,1,{printf "C31C path\\n"; g}')
    m.debugger:command('bpset 0x03280e,1,{printf "OK280E\\n"; g}')
    m.debugger:command('bpset 0x210b9c,1,{printf "RET r0=%04X\\n",r0; g}')
    m.debugger:command('wpiset 0x201f,1,w,1,{printf "FDCW %02X\\n",wpdata&ff; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch.lua")
