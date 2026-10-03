-- Watch writes to the unit table (fixed address UT, 0x20 bytes) from WATCH_T.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local armed = false
emu.register_frame_done(function()
    if armed or emu.time() < tonumber(os.getenv("WATCH_T")) then return end
    armed = true
    m.debugger:command(string.format('wpdset 0x%s,0x20,w,1,{printf "INITW pc=%%06X addr=%%04X data=%%04X r0=%%04X r1=%%04X r2=%%04X r3=%%04X r4=%%04X r5=%%04X r6=%%04X r7=%%04X\\n",pc,wpaddr,wpdata,r0,r1,r2,r3,r4,r5,r6,r7; g}', os.getenv("UT")))
end)
dofile(HERE .. "run_keys.lua")
