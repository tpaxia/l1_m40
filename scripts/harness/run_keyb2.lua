local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 76.2 then return end
    done = true
    m.debugger:command('wpiset 0x201f,1,w,1,{printf "W %02X\\n",wpdata&ff; g}')
    m.debugger:command('wpiset 0x201f,1,r,1,{printf "R %02X\\n",wpdata&ff; g}')
    m.debugger:command('bpset 0x210bc4,1,{printf "POST r5=%04X dev=%04X ac=%04X\\n",r5,dw@(r5+4),dw@(dw@(r5+4)+ac); g}')
end)
dofile(HERE .. "run_descpatch_ext2.lua")
