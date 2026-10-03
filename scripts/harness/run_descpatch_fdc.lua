local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 75.5 then return end
    done = true
    m.debugger:command('wpiset 0x201f,1,w,1,{printf "FDCW pc=%06X data=%02X\\n",pc,wpdata&ff; g}')
    m.debugger:command('wpiset 0x201f,1,r,1,{printf "FDCR pc=%06X data=%02X\\n",pc,wpdata&ff; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch.lua")
