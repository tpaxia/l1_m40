-- Focused MDOS30 slot/config probe.
--
-- Reuses the normal M40 diagnostic trace helper, then adds:
--   * reads/writes to the ROM config table at <<1>>0x0230..0x026f
--   * all I/O accesses to physical slot/window E (0xe000..0xe0ff)
--   * a periodic snapshot while the CPU spins in MDOS segment 0x3e

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local out_path = os.getenv("M40_SLOT_TRACE") or os.getenv("M40_EXTRA_TRACE") or "/tmp/m40_mdos30_slot_probe.log"
local out = assert(io.open(out_path, "w"))

local cpu = manager.machine.devices[":maincpu"]
local io = cpu.spaces["io_std"]
local sio = cpu.spaces["io_spc"]
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local state = cpu.state
local taps = {}

local eio_count = 0
local eio_limit = tonumber(os.getenv("M40_EIO_LIMIT") or "2000")
local last_pc = 0
local last_snapshot = ""
local last_config = ""
local last_config_time = -1
local last_pc3e_time = -1

local function log(fmt, ...)
	out:write(string.format(fmt, ...) .. "\n")
	out:flush()
end

local function pc()
	return state["PC"] and state["PC"].value or 0
end

local function reg(name)
	return state[name] and state[name].value or 0
end

local function bus_byte(data, mask)
	if mask == 0xff00 then
		return (data >> 8) & 0xff
	elseif mask == 0x00ff then
		return data & 0xff
	end
	return data & 0xff
end

local function install_read_tap(space, start, finish, name, cb)
	taps[#taps + 1] = space:install_read_tap(start, finish, name, cb)
end

local function install_write_tap(space, start, finish, name, cb)
	taps[#taps + 1] = space:install_write_tap(start, finish, name, cb)
end

local function log_regs(prefix)
	log("%s pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
		prefix, pc(), reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R14"), reg("R15"))
end

local function config_snapshot(label)
	local parts = {}
	for slot = 0, 15 do
		local base = (0x01 << 16) | 0x0230 | (slot << 2)
		local t = data_space:read_u8(base)
		local hi = data_space:read_u8(base + 2)
		local lo = data_space:read_u8(base + 3)
		parts[#parts + 1] = string.format("%X:%02X-%02X%02X", slot, t, hi, lo)
	end
	local snapshot = table.concat(parts, " ")
	if snapshot ~= last_config or label ~= "periodic" then
		last_config = snapshot
		log("CONFIG %s %s", label, snapshot)
	end
end

local function install_config_taps(space, space_name)
	if not space then
		return
	end
	install_write_tap(space, (0x01 << 16) | 0x0230, (0x01 << 16) | 0x026f, "cfg_" .. space_name .. "_w", function(addr, data, mask)
	local slot = ((addr & 0xffff) - 0x0230) >> 2
	log("CFG W space=%s pc=%08X addr=%06X slot=%X off=%02X data=%04X byte=%02X mask=%04X",
		space_name, pc(), addr, slot, addr & 3, data & 0xffff, bus_byte(data, mask), mask & 0xffff)
	if slot == 0x0e then
		log_regs("CFG-E CTX")
	end
	end)

	install_read_tap(space, (0x01 << 16) | 0x0230, (0x01 << 16) | 0x026f, "cfg_" .. space_name .. "_r", function(addr, data, mask)
	local p = pc()
	local slot = ((addr & 0xffff) - 0x0230) >> 2
	if p >= 0x00000600 or slot == 0x0e then
		log("CFG R space=%s pc=%08X addr=%06X slot=%X off=%02X data=%04X byte=%02X mask=%04X",
			space_name, p, addr, slot, addr & 3, data & 0xffff, bus_byte(data, mask), mask & 0xffff)
		if slot == 0x0e then
			log_regs("CFG-E CTX")
		end
	end
	end)
end

install_config_taps(program, "program")
install_config_taps(data_space, "data")

local function install_slot_e_taps(space, space_name)
	if not space then
		return
	end
	install_read_tap(space, 0xe000, 0xe0ff, "slot_e_" .. space_name .. "_r", function(addr, data, mask)
	eio_count = eio_count + 1
	if eio_count <= eio_limit or (addr & 0xff) ~= 0x08 then
		log("EIO R space=%s pc=%08X addr=%04X reg=%02X data=%04X byte=%02X mask=%04X",
			space_name, pc(), addr, addr & 0xff, data & 0xffff, bus_byte(data, mask), mask & 0xffff)
		if (addr & 0xff) == 0x08 or (addr & 0xff) == 0xff or (addr & 0xff) == 0xfe then
			log_regs("EIO CTX")
		end
	end
	end)

	install_write_tap(space, 0xe000, 0xe0ff, "slot_e_" .. space_name .. "_w", function(addr, data, mask)
	eio_count = eio_count + 1
	if eio_count <= eio_limit or (addr & 0xff) ~= 0x08 then
		log("EIO W space=%s pc=%08X addr=%04X reg=%02X data=%04X byte=%02X mask=%04X",
			space_name, pc(), addr, addr & 0xff, data & 0xffff, bus_byte(data, mask), mask & 0xffff)
		log_regs("EIO CTX")
	end
	end)
end

install_slot_e_taps(io, "std")
install_slot_e_taps(sio, "spc")

emu.register_periodic(function()
	local p = pc()
	local now = os.clock()
	if p ~= last_pc and (p >= 0x003e0000 and p <= 0x003e0800) and now - last_pc3e_time >= 0.25 then
		last_pc3e_time = now
		last_pc = p
		local snapshot = string.format("pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
			p, reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
			reg("R6"), reg("R7"), reg("R14"), reg("R15"))
		if snapshot ~= last_snapshot then
			last_snapshot = snapshot
			log("PC3E %s", snapshot)
		end
	end
end)

log("slot probe started")
config_snapshot("start")
emu.register_periodic(function()
	local now = os.clock()
	if now - last_config_time >= 1.0 then
		last_config_time = now
		config_snapshot("periodic")
	end
end)
