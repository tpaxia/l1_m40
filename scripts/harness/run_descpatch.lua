-- Diagnostic: poll the load descriptor at DESC (data space) every frame; once
-- byte 3 == 0x83 and byte 2 == 0x81, set byte 2 bit 4 (0x91) so the loader
-- skips the logical-unit check. Logs to OUT/patch.txt. Polling starts at
-- POLL_FROM (default 73 s): reading guest memory during ROM start-up raises
-- bus NMIs (unpopulated addresses) and breaks the boot.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local ds = m.devices[":cpu:uc042:maincpu"].spaces["data"]
local a = tonumber(os.getenv("DESC"), 16)
local f = io.open(os.getenv("OUT") .. "/patch.txt", "w")
local done = false
local from = tonumber(os.getenv("POLL_FROM") or "73")
emu.register_frame_done(function()
    if done or emu.time() < from then return end
    if ds:read_u8(a + 3) == 0x83 and ds:read_u8(a + 2) == 0x81 then
        ds:write_u8(a + 2, 0x91)
        done = true
        f:write(string.format("t=%.4f patched %04X: %02X %02X %02X %02X\n", emu.time(), a,
            ds:read_u8(a), ds:read_u8(a + 1), ds:read_u8(a + 2), ds:read_u8(a + 3))); f:flush()
    end
end)
dofile(HERE .. "run_keys.lua")
