-- run_descpatch_ext2.lua (oslem7+ hack stack) plus segment dumps at DUMP_T.
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local done = false
emu.register_frame_done(function()
    if done or emu.time() < tonumber(os.getenv("DUMP_T")) then return end
    done = true
    local sp = cpu.spaces["program"]
    for s in os.getenv("DUMP_SEGS"):gmatch("%x+") do
        local seg = tonumber(s, 16)
        local f = io.open(string.format("%s/seg%02X.bin", os.getenv("OUT"), seg), "wb")
        for a = seg * 0x10000, seg * 0x10000 + 0xffff do f:write(string.char(sp:read_u8(a))) end
        f:close()
    end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_descpatch_ext2.lua")
