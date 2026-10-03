-- run_keys.lua plus a PC histogram between PC_FROM and PC_TO seconds (pcs.txt).
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local t0, t1 = tonumber(os.getenv("PC_FROM") or "0"), tonumber(os.getenv("PC_TO") or "0")
local counts, done = {}, false
emu.register_periodic(function()
    local t = emu.time()
    if t >= t0 and t < t1 then
        local pc = cpu.state["PC"].value; counts[pc] = (counts[pc] or 0) + 1
    elseif t >= t1 and not done then
        done = true
        local l = {} for pc, c in pairs(counts) do l[#l + 1] = {pc, c} end
        table.sort(l, function(a, b) return a[2] > b[2] end)
        local f = io.open(os.getenv("OUT") .. "/pcs.txt", "w")
        for i = 1, math.min(#l, 30) do f:write(string.format("%06X %d\n", l[i][1], l[i][2])) end
        f:close()
    end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/harness/run_keys.lua")
