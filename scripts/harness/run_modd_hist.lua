-- At WATCH_T: find the segment holding MODD (header name at offset 0), then break at
-- MODD+DISP (dispatch entry) and MODD+ATT (attention entry), logging r0 and flags word.
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local watch_t = tonumber(os.getenv("WATCH_T") or "0")
local disp = tonumber(os.getenv("DISP") or "0x260")
local att = tonumber(os.getenv("ATT") or "0x32c")
local base = os.getenv("OUT") .. "/"
local armed = false
emu.register_frame_done(function()
    if armed or emu.time() < watch_t then return end
    armed = true
    local sp = cpu.spaces["program"]
    local log = io.open(base .. "modd.txt", "w")
    for seg = 0, 0x7f do
        local s = ""
        for i = 0, 3 do s = s .. string.char(sp:read_u8(seg * 0x10000 + i)) end
        if s == "MODD" then
            log:write(string.format("MODD at segment %02X\n", seg))
            m.debugger:command(string.format('bpset 0x%06X,1,{printf "DISP r0=%%04X r11=%%04X r4=%%04X r5=%%04X\\n",r0,r11,r4,r5; history 0,60; g}', seg * 0x10000 + disp))
            m.debugger:command(string.format('bpset 0x%06X,1,{printf "ATTENTRY r11=%%04X\\n",r11; g}', seg * 0x10000 + att))
        end
    end
    log:close()
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
