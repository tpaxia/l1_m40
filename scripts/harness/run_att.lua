-- run_keys.lua plus: at WATCH_T arm read watchpoints on the attention/error program
-- names (00:010E, 00:0116) and log pc/regs to debug output.
local m = manager.machine
local watch_t = tonumber(os.getenv("WATCH_T") or "0")
local armed = false
local cpu = m.devices[":cpu:uc042:maincpu"]
emu.register_frame_done(function()
    if not armed and watch_t > 0 and emu.time() >= watch_t then
        armed = true
        m.debugger:command('wpdset 0x010e,4,r,1,{printf "ATTNAME pc=%06X addr=%06X data=%04X r0=%04X r1=%04X r2=%04X r3=%04X r15=%04X\\n",pc,wpaddr,wpdata,r0,r1,r2,r3,r15; g}')
        m.debugger:command('wpdset 0x0116,4,r,1,{printf "ERRNAME pc=%06X addr=%06X data=%04X\\n",pc,wpaddr,wpdata; g}')
    end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
