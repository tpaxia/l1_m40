-- TEMP: bounded read-only I/O/instruction trace plus normal key input.
local m = manager.machine
local dir = assert(os.getenv("BCOS_SPACE_DIR"))
local cpu = m.devices[":cpu:uc042:maincpu"]
local log = assert(io.open(dir .. "/trace.log", "w"))
local keys = {}
for _, port in pairs(m.ioport.ports) do
    for name, field in pairs(port.fields) do keys[name] = field end
end
local clear = assert(keys["Keypad top-left (49)"])
local key_name = os.getenv("BCOS_TEST_KEY") or "SPACE (12)"
local space = assert(keys[key_name], key_name)
log:write("TEST_KEY " .. key_name .. "\n")
local taps, until_time, count = {}, 0, 0
for name, s in pairs(cpu.spaces) do
    if name:find("io") then
        for _, direction in ipairs({"read", "write"}) do
            taps[#taps+1] = s["install_" .. direction .. "_tap"](s, 0x1000, 0x1fff, "space-" .. name .. direction,
                function(a,d,mask)
                    log:write(string.format("IO %.9f %s %04X %04X %04X pc=%06X\n", emu.time(), direction, a,d,mask,cpu.state.PC.value))
                end)
        end
    end
end
taps[#taps+1] = cpu.spaces.program:install_read_tap(0, 0x7fffff, "space-cpu", function(a,d,mask)
    if emu.time() > until_time or count >= 60000 or a ~= cpu.state.PC.value then return end
    count = count + 1
    log:write(string.format("CPU %.9f %06X %04X", emu.time(),a,d))
    for n=0,15 do log:write(string.format(" %04X",cpu.state["R"..n].value)) end
    log:write("\n")
end)
local function snapshot(stem)
    m.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. stem .. ".png")
    for _, tag in ipairs({":ram", ":cpu:uc042:mmu"}) do
        for name, index in pairs(m.devices[tag].items) do
            if name:match("m_pointer$") or name:match("m_sdr$") then
                local item = emu.item(index)
                local f = assert(io.open(dir .. "/" .. stem .. "-" .. name:match("([^/]+)$") .. ".bin", "wb"))
                f:write(item:read_block(0,item.size*item.count)); f:close()
            end
        end
    end
end
local frame = 0
emu.register_frame_done(function()
    assert(taps)
    frame = frame + 1
    if frame == 1 then snapshot("before") end
    if frame == 30 then clear:set_value(1) end
    if frame == 35 then clear:set_value(0) end
    if frame == 70 then snapshot("cleared") end
    if frame == 90 then space:set_value(1); until_time = emu.time() + 0.15 end
    if frame == 95 then space:set_value(0) end
    if frame == 180 then snapshot("after"); log:close(); m:exit() end
end)
