-- Temporary read-only trace of diagnostic drive selection; disposable media only.
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_timed_keys.lua")
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local stem = assert(os.getenv("M40_FINAL_SNAPSHOT"))
local log = assert(io.open(stem .. ".fdc.log", "w"))
local taps = {}
for name, space in pairs(cpu.spaces) do
    if name:find("io") then
        local function observe(kind,a,d,m)
            if emu.time() < 130 or (a & 0xfe) ~= 0x1e then return end
            log:write(string.format("%.9f pc=%08X %s %s port=%04X data=%04X mask=%04X\n",
                emu.time(),cpu.state.PC.value,name,kind,a,d,m))
            log:flush()
        end
        taps[#taps+1] = space:install_read_tap(0x2000,0x2fff,"diag-fdu-r-"..name,
            function(a,d,m) observe("R",a,d,m) end)
        taps[#taps+1] = space:install_write_tap(0x2000,0x2fff,"diag-fdu-w-"..name,
            function(a,d,m) observe("W",a,d,m) end)
    end
end
local captures = {120,140,160,180,200,220}
local next_capture = 1
emu.register_frame_done(function()
    assert(taps)
    if captures[next_capture] and emu.time() >= captures[next_capture] then
        manager.machine.screens[":slot3:go252:screen"]:snapshot(stem .. "." .. captures[next_capture] .. ".png")
        next_capture = next_capture+1
    end
end)
