-- Temporary read-only FDC trace; replay FDn input from a saved prompt.
-- Use only with disposable media and a copy of the user's saved state.
-- BCOS_FD_TRACE_DIR is required; BCOS_FD_QUERY defaults to FD2.
local dir = assert(os.getenv("BCOS_FD_TRACE_DIR"))
local query = os.getenv("BCOS_FD_QUERY") or "FD2"
assert(query:match("^FD[0-5]$"))
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
-- Diagnostic only: test whether a stale per-drive status prevents any read.
-- Never enable for a normal run; this is not an emulation fix.
local function status_probe()
if os.getenv("BCOS_FD_STATUS_PROBE") then
    for name, index in pairs(manager.machine.devices[":ram"].items) do
        if name:match("m_pointer$") then
            local ram = emu.item(index)
            assert(ram:read(0x13115) == 0x08, "unexpected saved FD2 status")
            ram:write(0x13115, 0x04)
        end
    end
end
end
local output = assert(io.open(dir .. "/fdc.log", "w"))
local taps, fields = {}, {}
local shift, enter
for tag, port in pairs(manager.machine.ioport.ports) do
    for name, field in pairs(port.fields) do
        if name == "SHIFT (6E/76)" then shift = field end
        if name == "Keypad ENTER (61)" then enter = field end
        if name == "Left (4A)" then fields["<"] = field end
        if name == "Keypad top-left (49)" then fields["!"] = field end
        if name:match("^[A-Za-z]$") then fields[name:upper()] = field end
        if tag == ":slot3:go252:keyboard:K5" then
            if field.mask == 0x1000 then fields["0"] = field end
            if field.mask == 0x200 then fields["1"] = field end
            if field.mask == 0x400 then fields["2"] = field end
            if field.mask == 0x800 then fields["3"] = field end
            if field.mask == 0x20 then fields["4"] = field end
            if field.mask == 0x40 then fields["5"] = field end
        end
    end
end
assert(shift and enter and fields.F and fields.D and fields[query:sub(3)])
fields["\n"] = enter
assert(fields["<"])
query = "!<" .. query .. "\n"
local count = 0
local trace_until, instruction_count = 0, 0
local instructions
if os.getenv("BCOS_FD_CPU_TRACE") then
    instructions = assert(io.open(dir .. "/cpu.log", "w"))
    taps[#taps + 1] = cpu.spaces.program:install_read_tap(0, 0x7fffff, "label-cpu",
        function(a,d,m)
            if emu.time() > trace_until or instruction_count >= 100000 or a ~= cpu.state.PC.value then return end
            if emu.time() < trace_until - 4.91 or emu.time() > trace_until - 4.86 then return end
            instruction_count = instruction_count + 1
            instructions:write(string.format("%.9f pc=%06X op=%04X", emu.time(), a, d))
            for n=0,15 do instructions:write(string.format(" r%d=%04X", n, cpu.state["R" .. n].value)) end
            instructions:write("\n")
        end)
end
local function observe(kind, a, d, m)
    if kind:sub(1,1) == "R" and a >= 0x1000 and a < 0x2000 and (a & 0xff) == 2 and (d & 0xff) == 0x61 then
        trace_until = emu.time() + 5
    end
    local reg = a & 0xfe
    -- Include both byte lanes: CPU taps may report the aligned word address.
    if not os.getenv("BCOS_FD_ALL_IO") and reg ~= 0x1e and reg ~= 0xe6 and reg ~= 0xf6
        and not (kind == "W" and reg >= 0x40 and reg <= 0x5e) then return end
    if count >= 20000 then return end
    count = count + 1
    output:write(string.format("%.9f pc=%08X %s port=%04X data=%04X mask=%04X\n",
        emu.time(), cpu.state.PC.value, kind, a, d, m))
    output:flush()
end
for space_name, space in pairs(cpu.spaces) do
    output:write("SPACE " .. space_name .. "\n")
    if space_name:find("io") then
    if space then
        taps[#taps + 1] = space:install_read_tap(0, 0xffff, "label-read-" .. space_name,
            function(a,d,m) observe("R-" .. space_name, a,d,m) end)
        taps[#taps + 1] = space:install_write_tap(0, 0xffff, "label-write-" .. space_name,
            function(a,d,m) observe("W", a,d,m) end)
    end
    end
end
local function snapshot(stem)
    for _, tag in ipairs({":ram", ":cpu:uc042:mmu"}) do
        for name, index in pairs(manager.machine.devices[tag].items) do
            if name:match("m_pointer$") or name:match("m_sdr$") then
                local item = emu.item(index)
                local f = assert(io.open(dir .. "/" .. stem .. "-" .. name:match("([^/]+)$") .. ".bin", "wb"))
                f:write(item:read_block(0, item.size * item.count))
                f:close()
            end
        end
    end
    manager.machine.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. stem .. ".png")
end
local frames, step = 0, 0
emu.register_frame_done(function()
    assert(taps)
    frames = frames + 1
    if frames == 1 then snapshot("before"); status_probe() end
    if frames >= 50 and frames % 5 == 0 and step < #query * 4 then
        local char = query:sub(math.floor(step / 4) + 1, math.floor(step / 4) + 1)
        local phase = step % 4
        if phase == 0 then shift:set_value(char:match("%u") and 1 or 0)
        elseif phase == 1 then fields[char]:set_value(1)
        elseif phase == 2 then fields[char]:set_value(0)
        else shift:set_value(0) end
        step = step + 1
    end
    if frames == 600 then
        snapshot("after")
        output:close()
        if instructions then instructions:close() end
        manager.machine:exit()
    end
end)
