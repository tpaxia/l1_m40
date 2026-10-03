-- No hacks. Arms the PROBE debugger commands ('|'-separated) at the first frame at
-- or after ARM_T seconds (default 0; debugger breakpoints are safe during ROM
-- start-up, Lua guest-memory reads are not), then runs run_keys.lua.
-- Needs DEBUG=1 and -debugscript with "go". Multi-command -debugscript files with
-- {…} actions did not set breakpoints; use this instead.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local armed = false
emu.register_frame_done(function()
    if armed or emu.time() < tonumber(os.getenv("ARM_T") or "0") then return end
    armed = true
    for c in (os.getenv("PROBE") or ""):gmatch("[^|]+") do
        m.debugger:command(c)
    end
end)
dofile(os.getenv("RUN_KEYS") or HERE .. "run_keys.lua")
