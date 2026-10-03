-- oslem7+ HACK STACK (working hack, not a fix):
--  1. run_descpatch.lua: load descriptor 00:CC30 byte 2 bit 4 (skip unit-3 check)
--  2. KIO0 MX82 range check: at 03:2956 (after r3 = request +0x84), for normal
--     (non-0xC000) addresses with +0x84 == 0, use length 0x0F08 (floppy data
--     area) in the register only; special track-0 addresses keep their path.
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    m.debugger:command('bpset 0x032956,{r3==0 && (r0&8000)==0},{r3=f08; fcw=fcw&ffbf; g}')
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch.lua")
