-- Once the kernel pointer 00:00A8 is set, locate the logical-unit table
-- (word [A8]+6) and log all writes to units 0..7 (data space), plus a
-- snapshot of units 0..7 every second.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local ds = cpu.spaces["data"]
local out = io.open(os.getenv("OUT") .. "/units.txt", "w")
local armed, base, last = false, nil, -1
emu.register_frame_done(function()
    local t = emu.time()
    if t < 60 then return end
    local p = ds:read_u16(0x00a8)
    if not armed and p ~= 0 and p ~= 0xffff then
        local b = ds:read_u16(p + 6)
        if b ~= 0 and b ~= 0xffff then
            armed, base = true, b
            out:write(string.format("t=%.3f A8=%04X table=%04X\n", t, p, b)); out:flush()
            m.debugger:command(string.format('wpdset 0x%04X,0x20,w,1,{printf "UNITW pc=%%06X addr=%%04X data=%%04X r0=%%04X r1=%%04X r2=%%04X r3=%%04X\\n",pc,wpaddr,wpdata,r0,r1,r2,r3; g}', b))
        end
    end
    if armed and math.floor(t) ~= last then
        last = math.floor(t)
        local s = string.format("t=%d", last)
        for u = 0, 7 do s = s .. string.format(" u%d=%04X", u, ds:read_u16(base + u * 4)) end
        out:write(s .. "\n"); out:flush()
    end
end)
dofile(HERE .. "run_keys.lua")
