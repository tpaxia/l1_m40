local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x210b9a,1,{printf "REQ  pc=%06X rr4=%04X:%04X blk18=%04X:%04X fw=%04X\\n",pc,r4,r5,dw@(r5+18),dw@(r5+1a),dw@(dw@(r5+1a)+2); g}')
    m.debugger:command('bpset 0x0326b4,1,{printf "CHK  pc=%06X rr6=%04X:%04X rr2=%04X:%04X word=%04X\\n",pc,r6,r7,r2,r3,dw@r3; g}')
end)
dofile(HERE .. "run_descpatch.lua")
