-- Saved-state snapshots, optional read-only I/O taps and physical key input.
local dir = assert(os.getenv("BCOS_STATE_DIR") or os.getenv("M40_SERIES_DIR"))
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local times = {70, 74, 90, 110, 119, 139, 159, 199, 219}
local typing = os.getenv("BCOS_TYPE") or ""
local type_at = tonumber(os.getenv("BCOS_TYPE_AT") or "100")
local type_step = 0
local command = os.getenv("BCOS_COMMAND") or ""
local command_at = tonumber(os.getenv("BCOS_COMMAND_AT") or "130")
local command_step = 0
local followup = os.getenv("BCOS_FOLLOWUP") or ""
local followup_at = tonumber(os.getenv("BCOS_FOLLOWUP_AT") or "145")
local followup_step = 0
local type_fields = {}
local shift_field
for _, port in pairs(manager.machine.ioport.ports) do
    for name, field in pairs(port.fields) do
        local digit = name:match("^(%d) ")
        if digit then type_fields[digit] = field end
        if name == "RETURN (35)" then
            type_fields["\n"] = field
            type_fields["\t"] = field -- test token: main Enter, even in keypad mode
        end
        if name == "BS (31)" then type_fields["\b"] = field end
        if name == "SPACE (12)" then type_fields[" "] = field end
        if name == "RES (51)" then type_fields["\r"] = field end
        if name == "Keypad top-left (49)" then type_fields["!"] = field end
        if name == "Left (4A)" then type_fields["<"] = field end
        if name == "LIST (54)" then type_fields["@"] = field end
        if name == "F16/F8 (5A)" then type_fields["#"] = field end
        local letter = name:lower():match("^([a-z])$")
        if letter then
            type_fields[letter] = field
            type_fields[letter:upper()] = field
        end
        if name == "SHIFT (6E/76)" then shift_field = field end
    end
end
if os.getenv("BCOS_KEYPAD") then
    local masks = {[0]=0x1000, [1]=0x200, [2]=0x400, [3]=0x800,
        [4]=0x20, [5]=0x40, [6]=0x80, [7]=2, [8]=4, [9]=8}
    for name, field in pairs(manager.machine.ioport.ports[":slot3:go252:keyboard:K5"].fields) do
        for digit, mask in pairs(masks) do
            if field.mask == mask then type_fields[tostring(digit)] = field end
        end
        if name == "Keypad ENTER (61)" then type_fields["\n"] = field end
    end
end
for n = 1, #typing do assert(type_fields[typing:sub(n, n)], "unsupported BCOS_TYPE character") end
for n = 1, #command do assert(type_fields[command:sub(n, n)], "unsupported BCOS_COMMAND character") end
for n = 1, #followup do assert(type_fields[followup:sub(n, n)], "unsupported BCOS_FOLLOWUP character") end
local chord_time = tonumber(os.getenv("BCOS_CTRL_J_AT"))
local chord_step = 0
local keyboard_taps = {}
local error_until, late_reads = 0, 0
local error_key = tonumber(os.getenv("BCOS_ERROR_KEY") or "3")
if os.getenv("BCOS_ERROR_TRACE") then
    local output = assert(io.open(dir .. "/date-error-trace.log", "w"))
    local count = 0
    keyboard_taps[#keyboard_taps + 1] = cpu.spaces["program"]:install_read_tap(
        0, 0x7fffff, "bcos-date-error", function(a, d, m)
            if error_until == 0 or emu.time() > error_until or count >= 20000 then return end
            if a ~= cpu.state["PC"].value then return end
            count = count + 1
            output:write(string.format("t=%.9f pc=%06X op=%04X", emu.time(), a, d))
            for n = 0, 15 do output:write(string.format(" r%d=%04X", n, cpu.state["R" .. n].value)) end
            output:write("\n")
            output:flush()
        end)
end
if os.getenv("BCOS_KBD_EVENTS") then
    local events = assert(io.open(dir .. "/keyboard-events.log", "w"))
    local count = 0
    keyboard_taps[#keyboard_taps + 1] = cpu.spaces["program"]:install_read_tap(
        0x250000, 0x2503ef, "bcos-keyboard-events", function(a, d, m)
            local off = a & 0xffff
            if emu.time() < 99 or count >= 256 then return end
            if off ~= 0x15c and off ~= 0x250 and off ~= 0x256 and off ~= 0x22c and off ~= 0x4c then return end
            count = count + 1
            events:write(string.format("t=%.9f fetch=%06X pc=%06X", emu.time(), a, cpu.state["PC"].value))
            for n = 0, 15 do events:write(string.format(" r%d=%04X", n, cpu.state["R" .. n].value)) end
            events:write("\n")
            events:flush()
        end)
end
if os.getenv("BCOS_KBD_TRACE") then
    local out = assert(io.open(dir .. "/keyboard.log", "w"))
    local count = 0
    local late_count = 0
    local function observe(kind, address, data, mask)
        if (address & 0xff) > 3 then return end
        local late = emu.time() >= 94
        if (late and late_count >= 128) or (not late and count >= 512) then return end
        if kind == "R" and (address & 0xff) == 0 then return end
        if kind == "R" and late and (address & 0xff) == 2 then
            late_reads = late_reads + 1
            if late_reads == error_key then error_until = emu.time() + 0.025 end
        end
        if late then late_count = late_count + 1 else count = count + 1 end
        out:write(string.format("t=%.9f pc=%08X %s port=%04X data=%04X mask=%04X r0=%04X\n",
            emu.time(), cpu.state["PC"].value, kind, address, data, mask, cpu.state["R0"].value))
        out:flush()
    end
    local io_space = cpu.spaces["io_std"]
    keyboard_taps[#keyboard_taps + 1] = io_space:install_read_tap(0x1000, 0x1fff, "bcos-kbd-read",
        function(a, d, m)
            observe("R", a, d, m)
        end)
    keyboard_taps[#keyboard_taps + 1] = io_space:install_write_tap(0x1000, 0x1fff, "bcos-kbd-write",
        function(a, d, m)
            observe("W", a, d, m)
        end)
end
local control, j
if chord_time then
    for name, field in pairs(manager.machine.ioport.ports[":slot3:go252:keyboard:K3"].fields) do
        if name:find("CONTROL", 1, true) then control = field end
    end
    for name, field in pairs(manager.machine.ioport.ports[":slot3:go252:keyboard:K2"].fields) do
        if name:lower() == "j" or name:lower():match("^j%s") then j = field end
    end
    assert(control and j, "Ctrl+J matrix fields missing")
end
local next_capture = 1
local function dump_device(tag, stem)
    local dev = assert(manager.machine.devices[tag], tag)
    local info = assert(io.open(dir .. "/" .. stem .. ".txt", "w"))
    for name, index in pairs(dev.items) do
        local item = emu.item(index)
        info:write(string.format("%s index=%d size=%d count=%d\n", name, index, item.size, item.count))
        if name:match("m_pointer$") or name:match("m_sdr$") then
            local f = assert(io.open(dir .. "/" .. stem .. "-" .. name:match("([^/]+)$") .. ".bin", "wb"))
            f:write(item:read_block(0, item.size * item.count))
            f:close()
        elseif item.count <= 32 then
            for i = 0, item.count - 1 do info:write(string.format(" %X", item:read(i))) end
            info:write("\n")
        end
    end
    info:close()
end
emu.register_frame_done(function()
    assert(keyboard_taps) -- retain optional observers for this run
    if followup_step < #followup * 4 and emu.time() >= followup_at + followup_step * 0.1 then
        local char = followup:sub(math.floor(followup_step / 4) + 1, math.floor(followup_step / 4) + 1)
        local phase = followup_step % 4
        if phase == 0 then assert(shift_field):set_value(char:match("%u") and 1 or 0)
        elseif phase == 1 then type_fields[char]:set_value(1)
        elseif phase == 2 then type_fields[char]:set_value(0)
        else shift_field:set_value(0) end
        followup_step = followup_step + 1
    end
    if command_step < #command * 2 and emu.time() >= command_at + command_step * 0.2 then
        local char = command:sub(math.floor(command_step / 2) + 1, math.floor(command_step / 2) + 1)
        type_fields[char]:set_value(command_step % 2 == 0 and 1 or 0)
        command_step = command_step + 1
    end
    if type_step < #typing * 2 and emu.time() >= type_at + type_step * 0.2 then
        local char = typing:sub(math.floor(type_step / 2) + 1, math.floor(type_step / 2) + 1)
        type_fields[char]:set_value(type_step % 2 == 0 and 1 or 0)
        type_step = type_step + 1
    end
    if chord_time and chord_step < 4 and emu.time() >= chord_time + chord_step * 0.2 then
        if chord_step == 0 then control:set_value(1)
        elseif chord_step == 1 then j:set_value(1)
        elseif chord_step == 2 then j:set_value(0)
        else control:set_value(0) end
        chord_step = chord_step + 1
    end
    local t = times[next_capture]
    if not t or emu.time() < t then return end
    next_capture = next_capture + 1
    for _, pair in ipairs({{":ram:2m", "ram"}, {":cpu:uc042:mmu", "mmu"},
        {":cpu:uc042", "uc"}, {":slot3:go252", "kbd"}, {":slot4:go280", "fdu"}}) do
        dump_device(pair[1], tostring(t) .. "-" .. pair[2])
    end
    local f = assert(io.open(dir .. "/" .. t .. "-cpu.txt", "w"))
    for name, state in pairs(cpu.state) do f:write(string.format("%s=%X\n", name, state.value)) end
    f:close()
    manager.machine.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. t .. "-screen.png")
end)
