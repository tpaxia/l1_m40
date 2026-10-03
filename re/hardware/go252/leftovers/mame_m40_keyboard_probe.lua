-- Minimal GO252 keyboard probe for non-diagnostic M40 media.
-- It deliberately avoids the broad dynamic-slot taps in the diagnostic tracer.

local path = os.getenv("M40_KBD_TRACE") or "/tmp/m40_kbd.log"
local keys = os.getenv("M40_KEYS") or ""
local delay = tonumber(os.getenv("M40_KEY_DELAY") or "20")
local inter = tonumber(os.getenv("M40_INTER_KEY_DELAY") or "0.1")
local out = assert(io.open(path, "w"))
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local io = assert(cpu.spaces["io_std"])
local sio = assert(cpu.spaces["io_spc"])
local state = cpu.state
local taps = {}

local function pc()
	return state["PC"] and state["PC"].value or 0
end

local function cpu_state(label)
	out:write(string.format("%s pc=%08X fcw=%04X irq=%02X\n", label, pc(),
		state["FCW"] and state["FCW"].value or 0,
		state["IRQ_REQ"] and state["IRQ_REQ"].value or 0))
	out:flush()
end

local function byte(data, mask)
	return mask == 0xff00 and ((data >> 8) & 0xff) or (data & 0xff)
end

local function log(direction, addr, data, mask)
	out:write(string.format("KDC %s pc=%08X reg=%02X data=%02X mask=%04X\n",
		direction, pc(), addr & 0xff, byte(data, mask), mask & 0xffff))
	out:flush()
end

for _, base in ipairs({ 0x1000, 0x1f00, 0xff20 }) do
	taps[#taps + 1] = io:install_read_tap(base, base + 3,
		string.format("m40_kbd_probe_%04x_r", base),
		function(addr, data, mask) log("R", addr, data, mask) end)
	taps[#taps + 1] = io:install_write_tap(base, base + 3,
		string.format("m40_kbd_probe_%04x_w", base),
		function(addr, data, mask) log("W", addr, data, mask) end)
end

if os.getenv("M40_CTRL_J") then
	emu.wait(delay)
	cpu_state("CTRL-J before")
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
	assert(control, "CONTROL input field not found")
	assert(j, "J input field not found")
	control:set_value(1)
	cpu_state("CTRL-J control-make")
	emu.wait(inter)
	j:set_value(1)
	cpu_state("CTRL-J j-make")
	emu.wait(inter)
	j:set_value(0)
	emu.wait(inter)
	control:set_value(0)
	emu.wait(inter)
	cpu_state("CTRL-J after")
	out:write(string.format("CTRL-J PROBE status=%02X\n", io:read_u8(0x1f00)))
	out:write(string.format("MMU violation type=%02X seg=%02X off=%02X bcs=%02X iseg=%02X ioff=%02X\n",
		sio:read_u8(0x0200), sio:read_u8(0x0300), sio:read_u8(0x0400),
		sio:read_u8(0x0500), sio:read_u8(0x0600), sio:read_u8(0x0700)))
	out:flush()
elseif keys ~= "" then
	emu.wait(delay)
	local pos = 1
	while pos <= #keys do
		if keys:sub(pos, pos + 1) == "\\n" then
			manager.machine.natkeyboard:post_coded("{ENTER}")
			pos = pos + 2
		else
			manager.machine.natkeyboard:post(keys:sub(pos, pos))
			pos = pos + 1
		end
		emu.wait(inter)
	end
end
