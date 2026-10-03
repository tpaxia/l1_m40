-- Log every FDC data-register read returning 0x45 or 0x80 (ST0 / ST1 of the EN case).
local m = manager.machine
local armed = false
emu.register_frame_done(function()
    if armed or emu.time() < tonumber(os.getenv("WP_T") or "60") then return end
    armed = true
    m.debugger:command('wpiset 0x0000,0x10000,r,{(wpaddr&0xff)==0x1f && (wpdata&0xff)==0x45},{printf "ST45 t pc=%06X port=%04X data=%02X r10=%04X r11=%04X\\n",pc,wpaddr,wpdata,r10,r11; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
