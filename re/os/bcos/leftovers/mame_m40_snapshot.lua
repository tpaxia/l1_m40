-- Capture the GO252 display late in an unattended boot run.
local delay = tonumber(os.getenv("M40_SNAPSHOT_DELAY") or "170")
local settle = tonumber(os.getenv("M40_SNAPSHOT_SETTLE") or "0")
local path = assert(os.getenv("M40_SNAPSHOT"), "M40_SNAPSHOT is required")
local key_frame = tonumber(os.getenv("M40_SNAPSHOT_KEY_FRAME") or "0.1")
local early_kbd_start = os.getenv("M40_SNAPSHOT_EARLY_KBD_START")
local go252_select = tonumber(os.getenv("M40_SNAPSHOT_GO252_SELECT") or "1", 16)
assert(go252_select and go252_select >= 0 and go252_select <= 15,
    "M40_SNAPSHOT_GO252_SELECT must be a hexadecimal selector 0..f")
local go252_io_base = go252_select << 12

-- Optional observation-only trace for following a received keyboard byte from
-- GO252 into the resident BCOS handler.  Keep the tap object alive for the
-- duration of the script or MAME will remove the tap during garbage collection.
local go252_trace_path = os.getenv("M40_SNAPSHOT_GO252_TRACE")
local go252_trace
local go252_tap
if go252_trace_path then
    local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
    local io_space = assert(cpu.spaces["io_std"])
    local data_space = assert(cpu.spaces["data"])
    local state = cpu.state
    go252_trace = assert(io.open(go252_trace_path, "w"))
    local function reg(n)
        local item = state["R" .. n]
        return item and item.value or 0
    end
    -- Tap the whole selector window.  On the 16-bit Z8001 I/O space MAME may
    -- report a byte access using the containing word address rather than the
    -- byte register address, so a narrow 1002..1003 tap can miss an INB.
    go252_tap = io_space:install_read_tap(go252_io_base, go252_io_base | 0x0fff,
        "snapshot_go252_data", function(addr, data, mask)
            if (addr & 0xff) > 3 then
                return
            end
            local pointer = (((reg(2) >> 8) & 0x7f) << 16) | reg(3)
            go252_trace:write(string.format(
                "DATA pc=%08X addr=%04X data=%04X mask=%04X " ..
                "r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
                "r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
                "r12=%04X r13=%04X r14=%04X r15=%04X " ..
                "at_rr2=%04X,%04X,%04X,%04X\n",
                state["PC"].value, addr, data & 0xffff, mask & 0xffff,
                reg(0), reg(1), reg(2), reg(3), reg(4), reg(5), reg(6), reg(7),
                reg(8), reg(9), reg(10), reg(11), reg(12), reg(13), reg(14), reg(15),
                data_space:read_u16(pointer), data_space:read_u16(pointer + 2),
                data_space:read_u16(pointer + 4), data_space:read_u16(pointer + 6)))
            go252_trace:flush()
        end)
end

-- ioport_field:set_value() is incorporated on the next input-frame update.
-- Keep every new state for a second interval after that update so the matrix
-- scanner is guaranteed to observe it before the following transition.
local function hold_input(field, value)
    field:set_value(value)
    emu.wait(key_frame)
    emu.wait(key_frame)
end

if os.getenv("M40_ISL2") then
    local port = assert(manager.machine.ioport.ports[":cpu:uc042:ISL"])
    for _, field in pairs(port.fields) do field:set_value(0) end
end

local elapsed = 0
if early_kbd_start then
    local start_delay = assert(tonumber(early_kbd_start),
        "M40_SNAPSHOT_EARLY_KBD_START must be a number of seconds")
    assert(start_delay >= 0 and start_delay <= delay,
        "M40_SNAPSHOT_EARLY_KBD_START must not exceed M40_SNAPSHOT_DELAY")
    emu.wait(start_delay)
    local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
    local io_space = assert(cpu.spaces["io_std"])
    -- Controlled timing experiment only.  Send recovered-firmware command 00
    -- just after the BCOS keyboard driver consumes the startup FC, rather than
    -- waiting until the later injected key.  Do not treat this as real hardware
    -- behavior unless the missing host-side handshake is subsequently found.
    io_space:write_u8(go252_io_base | 0x0002, 0x00)
    io_space:write_u8(go252_io_base | 0x0000, 0x16)
    elapsed = start_delay
end

emu.wait(delay - elapsed)
if os.getenv("M40_SNAPSHOT_FORCE_KBD_START") then
    local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
    local io = assert(cpu.spaces["io_std"])
    -- Controlled compatibility probe only: command 00 ends the recovered
    -- 8049 startup loop; control 16 restores the BCOS receive mode.
    io:write_u8(go252_io_base | 0x0002, 0x00)
    io:write_u8(go252_io_base | 0x0000, 0x16)
    emu.wait(key_frame)
    emu.wait(key_frame)
end
local keys = os.getenv("M40_SNAPSHOT_KEYS")
if os.getenv("M40_SNAPSHOT_KEYPAD_ENTER") then
    local port = assert(manager.machine.ioport.ports[":slot3:go252:keyboard:K5"])
    local enter
    for name, field in pairs(port.fields) do
        if name == "Keypad ENTER (61)" then enter = field end
    end
    assert(enter, "keypad ENTER input field not found")
    local debug_path = os.getenv("M40_SNAPSHOT_INPUT_DEBUG")
    local debug = debug_path and assert(io.open(debug_path, "w")) or nil
    if debug then debug:write(string.format("before=%04X mask=%04X\n", port:read(), enter.mask)) end
    enter:set_value(1)
    if debug then debug:write(string.format("pressed=%04X\n", port:read())) end
    emu.wait(key_frame)
    if debug then debug:write(string.format("pressed-updated=%04X\n", port:read())) end
    emu.wait(key_frame)
    enter:set_value(0)
    emu.wait(key_frame)
    if debug then
        debug:write(string.format("released-updated=%04X\n", port:read()))
        debug:close()
    end
    emu.wait(key_frame)
elseif os.getenv("M40_SNAPSHOT_ALPHA_RETURN") then
    local port = assert(manager.machine.ioport.ports[":slot3:go252:keyboard:K1"])
    local enter
    for name, field in pairs(port.fields) do
        if name:find("RETURN", 1, true) then enter = field end
    end
    assert(enter, "alpha RETURN input field not found")
    hold_input(enter, 1)
    hold_input(enter, 0)
elseif os.getenv("M40_SNAPSHOT_PHYSICAL_X") then
    local port = assert(manager.machine.ioport.ports[":slot3:go252:keyboard:K3"])
    local x
    for name, field in pairs(port.fields) do
        if name:lower() == "x" or name:lower():match("^x%s") then x = field end
    end
    assert(x, "X input field not found")
    hold_input(x, 1)
    hold_input(x, 0)
elseif os.getenv("M40_SNAPSHOT_CTRL_J") then
    local ports = manager.machine.ioport.ports
    local control_port = assert(ports[":slot3:go252:keyboard:K3"])
    local j_port = assert(ports[":slot3:go252:keyboard:K2"])
    local control
    local j
    for name, field in pairs(control_port.fields) do
        if name:find("CONTROL", 1, true) then control = field end
    end
    for name, field in pairs(j_port.fields) do
        if name:lower() == "j" or name:lower():match("^j%s") then j = field end
    end
    assert(control and j, "CONTROL/J input fields not found")
    hold_input(control, 1)
    hold_input(j, 1)
    hold_input(j, 0)
    hold_input(control, 0)
elseif keys and keys ~= "" then
    manager.machine.natkeyboard:post(keys)
end

local command = os.getenv("M40_SNAPSHOT_COMMAND")
if command and command ~= "" then
    -- Optional follow-up for OSLEM experiments. Give the Ctrl+J handler time
    -- to establish Ready. Natural keyboard cannot synthesize upper-case letters
    -- for this matrix and maps newline to keypad ENTER, so drive the known SYS
    -- sequence and alpha RETURN as physical keys.
    emu.wait(1.0)
    assert(command:upper() == "SYS", "only physical command SYS is implemented")
    local ports = manager.machine.ioport.ports
    local function field_named(port_tag, wanted)
        local port = assert(ports[port_tag])
        for name, field in pairs(port.fields) do
            if name:lower() == wanted or name:lower():match("^" .. wanted .. "%s") then
                return field
            end
        end
        error("input field not found: " .. wanted)
    end
    local s = field_named(":slot3:go252:keyboard:K2", "s")
    local y = field_named(":slot3:go252:keyboard:K1", "y")
    local enter = field_named(":slot3:go252:keyboard:K1", "return")
    hold_input(s, 1)
    hold_input(s, 0)
    hold_input(y, 1)
    hold_input(y, 0)
    hold_input(s, 1)
    hold_input(s, 0)
    hold_input(enter, 1)
    hold_input(enter, 0)
end
emu.wait(settle)
local screen = assert(manager.machine.screens[":slot3:go252:screen"])
screen:snapshot(path)

local state_path = os.getenv("M40_SNAPSHOT_STATE")
if state_path then
    local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
    local out = assert(io.open(state_path, "w"))
    out:write(string.format("PC=%08X FCW=%04X IRQ_REQ=%02X\n",
        cpu.state["PC"].value, cpu.state["FCW"].value,
        cpu.state["IRQ_REQ"] and cpu.state["IRQ_REQ"].value or 0))
    if os.getenv("M40_SNAPSHOT_PROBE_KDC") then
        local space = assert(cpu.spaces["io_std"])
        local status = space:read_u8(go252_io_base | 0x0000)
        out:write(string.format("KDC_STATUS=%02X\n", status))
        if (status & 0x05) ~= 0 then
            out:write(string.format("KDC_DATA=%02X\n", space:read_u8(go252_io_base | 0x0002)))
        end
    end
    out:close()
end

if go252_trace then
    go252_trace:close()
end
