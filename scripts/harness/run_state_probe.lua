-- Runs after a -state load: arms hack v3 + PROBE debugger commands ('|'-separated)
-- once the restored machine time is past 73 s, then runs run_keys.lua.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local armed = false
emu.register_frame_done(function()
    if armed or emu.time() < 73 then return end
    armed = true
    -- hack v3: GO363 range check at 03:2956; v2 used 0F08 (= ff1 only), which
    -- rejects FF sectors >= 0F09 and data set 80 (0x372D long).
    local limit = os.getenv("LIMIT") or "7fff"
    m.debugger:command('bpset 0x032956,{r3==0 && (r0&8000)==0},{r3=' .. limit .. '; fcw=fcw&ffbf; g}')
    for c in (os.getenv("PROBE") or ""):gmatch("[^|]+") do
        m.debugger:command(c)
    end
end)
dofile(os.getenv("RUN_KEYS") or HERE .. "run_keys.lua")
