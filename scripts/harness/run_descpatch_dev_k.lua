local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x032452,1,{printf "DEV  rr4=%04X:%04X d8=%04X d6=%04X r10=%04X addr=%04X%04X req50=%04X req52=%04X\\n",r4,r5,dw@(r5+d8),dw@(r5+d6),r10,dw@(r7+6a),dw@(r7+6c),dw@(r7+50),dw@(r7+52); g}')
end)
dofile(HERE .. "run_descpatch.lua")
