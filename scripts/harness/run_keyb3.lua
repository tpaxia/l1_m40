local m = manager.machine
local a, b, state = tonumber(os.getenv("TR_FROM")), tonumber(os.getenv("TR_TO")), 0
emu.register_periodic(function()
    local t = emu.time()
    if state == 0 and t >= a then m.debugger:command("trace " .. os.getenv("OUT") .. "/trace.txt,,noloop"); state = 1
    elseif state == 1 and t >= b then m.debugger:command("trace off"); state = 2 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch_ext2.lua")
