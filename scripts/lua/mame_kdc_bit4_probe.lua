-- TEMP read-only trace of host KDC control writes; optional physical inputs
-- are supplied by the existing observer's BCOS_TYPE/COMMAND environment.
local m = manager.machine
local out = assert(io.open(os.getenv("M40_SERIES_DIR") .. "/control.log", "w"))
local cpu = m.devices[":cpu:uc042:maincpu"]
local tap = cpu.spaces.io_std:install_write_tap(0x1000,0x1fff,"kdc-control",function(a,d,mask)
    if (a & 0xff) > 1 then return end
    out:write(string.format("%.6f pc=%06X addr=%04X data=%04X mask=%04X\n",emu.time(),cpu.state.PC.value,a,d,mask))
    out:flush()
end)
emu.register_frame_done(function() assert(tap) end)
dofile("scripts/m40-os-observe.lua")
