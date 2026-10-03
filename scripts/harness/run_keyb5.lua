local m = manager.machine
local done, started = false, nil
local out = os.getenv("OUT")
emu.register_frame_done(function()
    if done or emu.time() < 77 then return end
    done = true
    m.debugger:command('bpset 0x2205cc,1,{printf "ATTACH r0=%04X r1=%04X\\n",r0,r1; trace ' .. out .. '/ktrace.txt,,noloop; g}')
end)
emu.register_periodic(function()
    local f = io.open(out .. "/ktrace.txt", "r")
    if f then f:close(); if not started then started = emu.time() end end
    if started and emu.time() > started + 3 then m.debugger:command("trace off"); started = 1e9 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch_ext2.lua")
