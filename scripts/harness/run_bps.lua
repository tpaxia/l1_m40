-- At BP_T set logging breakpoints: BPS="seg:off,seg:off,..." (hex). Logs pc and r0-r3, flags.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local t, done = tonumber(os.getenv("BP_T")), false
emu.register_frame_done(function()
    if done or emu.time() < t then return end
    done = true
    for s, o in (os.getenv("BPS") or ""):gmatch("(%x+):(%x+)") do
        m.debugger:command(string.format('bpset 0x%s%s,1,{printf "BP pc=%%06X r0=%%04X r1=%%04X r2=%%04X r3=%%04X fcw=%%04X\\n",pc,r0,r1,r2,r3,fcw; g}', s, string.format("%04x", tonumber(o, 16))))
    end
end)
dofile(HERE .. "run_keys.lua")
