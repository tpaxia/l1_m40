-- Diagnostic guest-memory patch: at BP_T arm a breakpoint at PATCH_AT (hex);
-- when hit run PATCH (debugger expressions, ';'-separated) once, log, continue.
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < tonumber(os.getenv("BP_T")) then return end
    done = true
    local p = os.getenv("PATCH")
    m.debugger:command(string.format('bpset 0x%s,1,{%s; printf "PATCHED pc=%%06X desc2=%%02X desc3=%%02X u3=%%04X\\n",pc,db@799e,db@799f,dw@7d5a; bpclear; g}', os.getenv("PATCH_AT"), p))
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
