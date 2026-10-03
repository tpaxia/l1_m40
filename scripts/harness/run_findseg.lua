-- At FIND_T, list segments whose offset 0 holds a module header named FIND (4 chars).
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local t, name, done = tonumber(os.getenv("FIND_T")), os.getenv("FIND"), false
emu.register_frame_done(function()
    if done or emu.time() < t then return end
    done = true
    local sp, f = cpu.spaces["program"], io.open(os.getenv("OUT") .. "/findseg.txt", "w")
    for seg = 0, 0x7f do
        for off = 0, 0xff00, 0x100 do
            local s = ""
            for i = 0, 7 do s = s .. string.char(sp:read_u8(seg * 0x10000 + off + i)) end
            if s:sub(1, 4) == name then f:write(string.format("%02X:%04X %s\n", seg, off, s)) end
        end
    end
    f:close()
end)
dofile(HERE .. "run_keys.lua")
