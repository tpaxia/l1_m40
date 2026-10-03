-- At BP_T set breakpoints at TRACE_AT (comma-separated hex, logical); when hit, start a CPU trace to
-- trace.txt; stop it TRACE_LEN seconds later.
local m = manager.machine
local t, done, started = tonumber(os.getenv("BP_T")), false, nil
local out = os.getenv("OUT")
emu.register_frame_done(function()
    if not done and emu.time() >= t then
        done = true
        for a in os.getenv("TRACE_AT"):gmatch("%x+") do
            m.debugger:command(string.format('bpset 0x%s,1,{printf "HIT pc=%%06X r0=%%04X r1=%%04X r2=%%04X r3=%%04X\\n",pc,r0,r1,r2,r3; trace %s/trace.txt,,noloop; g}', a, out))
        end
    end
end)
emu.register_periodic(function()
    local f = io.open(out .. "/trace.txt", "r")
    if f then f:close(); if not started then started = emu.time() end end
    if started and emu.time() > started + tonumber(os.getenv("TRACE_LEN") or "2") then
        m.debugger:command("trace off"); started = 1e9
    end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
