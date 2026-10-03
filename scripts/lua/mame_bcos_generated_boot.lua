-- TEMP fresh boot observer. Uses real configuration input, no RAM patches.
local m = manager.machine
local dir = assert(os.getenv("BCOS_GENERATED_DIR"))
if os.getenv("BCOS_GENERATED_ISL2") then
    for _, field in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do field.user_value = 0 end
end
local times = {10,30,50,69,90,94,99,109,119,139,159,179}
-- TEMP provenance: capture writes of LOAD/RUN prefix words in all CPU
-- memory spaces, including the copy-instruction source/destination registers.
local cpu = m.devices[":cpu:uc042:maincpu"]
local provenance = assert(io.open(dir .. "/volume-origin.log", "w"))
local taps = {}
-- Capture the READY-change interrupt handshake during the original swap.
for space_name, space in pairs(cpu.spaces) do
    if space_name:find("io") then
        for _, direction in ipairs({"read", "write"}) do
            taps[#taps+1] = space["install_" .. direction .. "_tap"](space,0x201e,0x201f,"swap-fdc",function(a,d,mask)
                if emu.time() < 89 or emu.time() > 96 then return end
                provenance:write(string.format("FDC %.9f %s %04X %04X mask=%04X pc=%06X\n",emu.time(),direction,a,d,mask,cpu.state.PC.value))
            end)
        end
    end
end
local handoff_step = 0
local drive, enter
if os.getenv("BCOS_GENERATED_SWAP") then
    for _, image in pairs(m.images) do if image.brief_instance_name == "flop1" then drive = image end end
    for _, port in pairs(m.ioport.ports) do
        for name, field in pairs(port.fields) do if name == "RETURN (35)" then enter = field end end
    end
    assert(drive); assert(enter)
    dofile("scripts/lua/mame_bcos_state.lua")
end
for space_name, space in pairs(cpu.spaces) do
    if not space_name:find("io") then
        taps[#taps+1] = space:install_write_tap(0,0x7fffff,"volume-prefix",function(a,d,mask)
            if d ~= 0x4c4f and d ~= 0x5255 then return end
            provenance:write(string.format("WRITE %s %.9f addr=%06X data=%04X mask=%04X pc=%06X",space_name,emu.time(),a,d,mask,cpu.state.PC.value))
            for n=0,15 do provenance:write(string.format(" R%d=%04X",n,cpu.state["R"..n].value)) end
            provenance:write("\n"); provenance:flush()
        end)
    end
end
local index = 1
emu.register_frame_done(function()
    assert(taps)
    if os.getenv("BCOS_GENERATED_SWAP") then
        local t = emu.time()
        if handoff_step == 0 and t >= 90 then
            if not os.getenv("BCOS_GENERATED_DIRECT_SWAP") then
                drive:unload()
                provenance:write("MEDIA eject LOAD at " .. t .. "\n")
            end
            handoff_step = 1
        elseif handoff_step == 1 and t >= 92 then
            local err = drive:load(dir .. "/run.imd"); assert(not err,tostring(err)); handoff_step = 2
            provenance:write("MEDIA insert RUN at " .. t .. "\n")
        elseif handoff_step == 2 and t >= 95 then
            enter:set_value(1); handoff_step = 3
        elseif handoff_step == 3 and t >= 95.15 then
            enter:set_value(0); handoff_step = 4
        end
    end
    if index <= #times and emu.time() >= times[index] then
        local stem = tostring(times[index])
        provenance:write(string.format("SNAPSHOT %s pc=%06X fcw=%04X\n",stem,cpu.state.PC.value,cpu.state.FCW.value)); provenance:flush()
        m.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. stem .. ".png")
        for _,tag in ipairs({":ram", ":cpu:uc042:mmu"}) do
            for name,id in pairs(m.devices[tag].items) do
                if name:match("m_pointer$") or name:match("m_sdr$") then
                    local item = emu.item(id)
                    local f = assert(io.open(dir .. "/" .. stem .. "-" .. name:match("([^/]+)$") .. ".bin","wb"))
                    f:write(item:read_block(0,item.size*item.count)); f:close()
                end
            end
        end
        if times[index] == 119 or index == #times then m:save(dir .. "/swap.sta") end
        index = index + 1
    end
end)
