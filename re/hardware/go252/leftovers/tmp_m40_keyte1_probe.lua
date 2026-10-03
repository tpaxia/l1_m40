local out_path = os.getenv("M40_EXTRA_TRACE") or "/tmp/m40_keyte1_extra.log"
local dump_dir = os.getenv("M40_DUMP_DIR") or "/tmp"
local post_wait = tonumber(os.getenv("M40_EXTRA_WAIT") or "30")
local cpu = manager.machine.devices[":maincpu"]
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local state = cpu.state

local out = assert(io.open(out_path, "w"))
local function log(fmt, ...)
	out:write(string.format(fmt, ...) .. "\n")
	out:flush()
end

local function reg(name)
	return state[name] and state[name].value or 0
end

local taps = {}
local function watch(space, start, finish, name)
	taps[#taps + 1] = space:install_write_tap(start, finish, name, function(addr, data, mask)
		log("WATCH %s pc=%08X addr=%06X data=%04X mask=%04X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
			name, reg("PC"), addr, data & 0xffff, mask & 0xffff,
			reg("R0"), reg("R1"), reg("R2"), reg("R3"), reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R14"), reg("R15"))
	end)
end

for _, space in ipairs({program, data_space}) do
	watch(space, 0x211730, 0x211731, "keyte1_flags_211730")
	watch(space, 0x21175e, 0x21175f, "keyte1_cmd_21175f")
	watch(space, 0x2116e6, 0x2116ff, "keyte1_desc_2116e6")
	watch(space, 0x04014e, 0x040161, "svc_go252_04014e")
	watch(space, 0x0401ce, 0x0401cf, "svc_result_0401ce")
	watch(space, 0x0401f2, 0x0401f3, "svc_state_0401f2")
end

local trace_script = "/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua"
dofile(trace_script)

local function dump_segment(seg)
	local path = string.format("%s/m40_seg_%02x.bin", dump_dir, seg)
	local f = assert(io.open(path, "wb"))
	for off = 0, 0xffff do
		f:write(string.char(program:read_u8((seg << 16) | off)))
	end
	f:close()
	log("DUMP seg=%02X path=%s", seg, path)
end

emu.wait(post_wait)
for i = 1, 20 do
	log("PC sample=%02d pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
		i, reg("PC"), reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R14"), reg("R15"))
	emu.wait(1)
end

for _, seg in ipairs({0x00, 0x02, 0x03, 0x04, 0x1d, 0x21, 0x3d}) do
	dump_segment(seg)
end

manager.machine:exit()
