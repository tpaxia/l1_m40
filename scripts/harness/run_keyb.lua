-- oslem7+ hack stack (run_descpatch_ext2.lua) plus probes for the KEYB stop.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local done = false
emu.register_frame_done(function()
    if done or emu.time() < 74 then return end
    done = true
    for _, a in ipairs({"210fd0", "0326b8", "03283c", "020bb0", "210b9c"}) do
        m.debugger:command('bpset 0x' .. a .. ',1,{printf "HIT pc=%06X r0=%04X r1=%04X r2=%04X r3=%04X\\n",pc,r0,r1,r2,r3; g}')
    end
end)
local counts, fin = {}, false
emu.register_periodic(function()
    local t = emu.time()
    if t > 85 and t < 100 then local pc = cpu.state["PC"].value; counts[pc] = (counts[pc] or 0) + 1
    elseif t >= 100 and not fin then
        fin = true
        local l = {} for pc, c in pairs(counts) do l[#l + 1] = {pc, c} end
        table.sort(l, function(a, b) return a[2] > b[2] end)
        local f = io.open(os.getenv("OUT") .. "/pcs.txt", "w")
        for i = 1, math.min(#l, 25) do f:write(string.format("%06X %d\n", l[i][1], l[i][2])) end
        f:close()
    end
end)
dofile(HERE .. "run_descpatch_ext2.lua")
