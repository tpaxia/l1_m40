-- run_descpatch.lua plus logging breakpoints BPS (seg:off list) armed at BP_T.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < tonumber(os.getenv("BP_T")) then return end
    done = true
    for s, o in (os.getenv("BPS") or ""):gmatch("(%x+):(%x+)") do
        m.debugger:command(string.format('bpset 0x%s%04x,1,{printf "BP t pc=%%06X r0=%%04X r1=%%04X r2=%%04X r3=%%04X\\n",pc,r0,r1,r2,r3; g}', s, tonumber(o, 16)))
    end
end)
dofile(HERE .. "run_descpatch.lua")
