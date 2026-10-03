-- As run_att.lua, but on the first ATTNAME hit dump segment 0x26 program space and the stack.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local watch_t = tonumber(os.getenv("WATCH_T") or "0")
local armed = false
local base = os.getenv("OUT") .. "/"
emu.register_frame_done(function()
    if not armed and watch_t > 0 and emu.time() >= watch_t then
        armed = true
        m.debugger:command('wpdset 0x010e,2,r,1,{printf "ATTNAME pc=%06X r14=%04X r15=%04X fcw=%04X\\n",pc,r14,r15,fcw; dump ' .. base .. 'stack.txt,0x' .. '0,0x0,2; g}')
    end
end)
local cpu = m.devices[":cpu:uc042:maincpu"]
local dumped = false
emu.register_frame_done(function()
    if armed and not dumped and emu.time() >= watch_t + 6.5 then
        dumped = true
        local sp = cpu.spaces["program"]
        local f = io.open(base .. "seg26.bin", "wb")
        for a = 0x260000, 0x26ffff do f:write(string.char(sp:read_u8(a))) end
        f:close()
        local d = cpu.spaces["data"]
        local g = io.open(base .. "data00.bin", "wb")
        for a = 0x000000, 0x00ffff do g:write(string.char(d:read_u8(a))) end
        g:close()
    end
end)
dofile(HERE .. "run_keys.lua")
