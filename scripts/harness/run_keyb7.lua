local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('wpdset 0x146a,2,w,1,{printf "W146A t pc=%06X data=%04X\\n",pc,wpdata; g}')
    m.debugger:command('wpdset 0x116a,2,w,1,{printf "W116A t pc=%06X data=%04X\\n",pc,wpdata; g}')
    m.debugger:command('bpset 0x03021c,1,{printf "WAIT %04X val=%04X\\n",r3,dw@r3; g}')
end)
dofile(HERE .. "run_descpatch_ext2.lua")
