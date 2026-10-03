-- oslem7+ HACK STACK v2 (working hack, not a fix):
--  1. logical unit 3 flags (00:D400) 0x0901 -> 0x0801 once the OS has set them,
--     so on-demand module loads really read from the boot library (unit 3)
--     instead of skipping the load (descriptor bit-4 hack, which crashed MONT
--     with a segment trap when JMDU was needed again).
--  2. KIO0 MX82 range check: at 03:2956, for normal (non-0xC000) addresses with
--     request +0x84 == 0, use length LIMIT (register only). v2 used 0x0F08
--     (ff1 only); v3 default 0x7FFF covers data sets FF and 80 (OSLEM_STATUS 1F).
-- Polling starts at 73 s (reading guest memory during ROM start-up breaks the boot).
local m = manager.machine
local ds = m.devices[":cpu:uc042:maincpu"].spaces["data"]
local f = io.open(os.getenv("OUT") .. "/patch.txt", "w")
local armed, n = false, 0
emu.register_frame_done(function()
    if emu.time() < 73 then return end
    if not armed then
        armed = true
        m.debugger:command('bpset 0x032956,{r3==0 && (r0&8000)==0},{r3=' .. (os.getenv("LIMIT") or "7fff") .. '; fcw=fcw&ffbf; g}')
    end
    if ds:read_u16(0xd400) == 0x0901 then
        ds:write_u16(0xd400, 0x0801); n = n + 1
        f:write(string.format("t=%.4f unit3 0901->0801 (#%d)\n", emu.time(), n)); f:flush()
    end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
