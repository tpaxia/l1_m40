-- Test-only observer for the ROM console progress port. No driver trace hooks.
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local console_tap = cpu.spaces["io_std"]:install_write_tap(0xffe0, 0xffe1,
    "rom-test-console", function(offset, data, mask)
        local value = mask == 0xff00 and ((data >> 8) & 0xff) or (data & 0xff)
        if value == 0x44 then
            print("ROM RAM phase complete: code = 0x44")
        end
    end)
-- Keep the tap alive for this run without coroutine-based scheduling.
emu.register_frame_done(function() assert(console_tap) end)
