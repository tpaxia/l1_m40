local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local out = assert(io.open(os.getenv("OUT") .. "/pc.log", "w"))
if os.getenv("ISL") == "floppy" then
    for _, f in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do f.user_value = 0 end
end
local last, n = 0, 0
emu.register_frame_done(function()
    local t = emu.time()
    n = n + 1
    if t >= last + 1 then
        last = last + 1
        local pcs = {}
        for i = 1, 8 do pcs[#pcs + 1] = string.format("%x", cpu.state["PC"].value) end
        out:write(string.format("t=%3d PC=%s\n", last, cpu.state["PC"].value and string.format("%06x", cpu.state["PC"].value)))
        out:flush()
    end
end)
