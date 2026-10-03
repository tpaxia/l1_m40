-- Watch the MDOS loader signature at 03:0024 ("J0XP") for corruption.
-- This installs write taps only and does not perform live MMU reads.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_J0XP_TRACE") or "/tmp/m40_mdos30_j0xp.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local taps = {}

local function reg(name)
	return state[name] and state[name].value or 0
end

local function install(space_name)
	local space = cpu.spaces[space_name]
	if not space then
		return
	end
	taps[#taps + 1] = space:install_write_tap(
		0x030026, 0x030027, "mdos_j0xp_" .. space_name,
		function(addr, data, mask)
			out:write(string.format(
				"space=%s addr=%06X data=%04X mask=%04X pc=%08X fcw=%04X " ..
				"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
				"r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
				"r12=%04X r13=%04X r14=%04X r15=%04X\n",
				space_name, addr, data, mask, reg("PC"), reg("FCW"),
				reg("R0"), reg("R1"), reg("R2"), reg("R3"),
				reg("R4"), reg("R5"), reg("R6"), reg("R7"),
				reg("R8"), reg("R9"), reg("R10"), reg("R11"),
				reg("R12"), reg("R13"), reg("R14"), reg("R15")))
			out:flush()
		end)
	taps[#taps + 1] = space:install_write_tap(
		0x000058, 0x00006f, "mdos_config_" .. space_name,
		function(addr, data, mask)
			out:write(string.format(
				"config space=%s addr=%06X data=%04X mask=%04X pc=%08X fcw=%04X " ..
				"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
				"r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
				"r12=%04X r13=%04X r14=%04X r15=%04X\n",
				space_name, addr, data, mask, reg("PC"), reg("FCW"),
				reg("R0"), reg("R1"), reg("R2"), reg("R3"),
				reg("R4"), reg("R5"), reg("R6"), reg("R7"),
				reg("R8"), reg("R9"), reg("R10"), reg("R11"),
				reg("R12"), reg("R13"), reg("R14"), reg("R15")))
			out:flush()
		end)
	local function fingerprint_read(addr, data, mask)
		local pc = reg("PC")
		if pc >= 0x003800e8 and pc <= 0x003800f2 then
			out:write(string.format(
				"fingerprint space=%s addr=%06X data=%04X mask=%04X pc=%08X " ..
				"r0=%04X r1=%04X r2=%04X r3=%04X r6=%04X r7=%04X\n",
				space_name, addr, data, mask, pc,
				reg("R0"), reg("R1"), reg("R2"), reg("R3"),
				reg("R6"), reg("R7")))
			out:flush()
		end
	end
	taps[#taps + 1] = space:install_read_tap(
		0x00e000, 0x00e0ff, "mdos_fingerprint_00_" .. space_name,
		fingerprint_read)
	taps[#taps + 1] = space:install_read_tap(
		0x3fe000, 0x3fe0ff, "mdos_fingerprint_3f_" .. space_name,
		fingerprint_read)
end

install("program")
install("data")

do
	local program = cpu.spaces["program"]
	local last_pc = -1
	taps[#taps + 1] = program:install_read_tap(
		0x030700, 0x030741, "mdos_segment2_overflow",
		function(addr, data, mask)
			local pc = reg("PC")
			if pc ~= last_pc then
				out:write(string.format(
					"sg2 addr=%06X data=%04X mask=%04X pc=%08X fcw=%04X " ..
					"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
					"r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
					"r12=%04X r13=%04X r14=%04X r15=%04X\n",
					addr, data, mask, pc, reg("FCW"),
					reg("R0"), reg("R1"), reg("R2"), reg("R3"),
					reg("R4"), reg("R5"), reg("R6"), reg("R7"),
					reg("R8"), reg("R9"), reg("R10"), reg("R11"),
					reg("R12"), reg("R13"), reg("R14"), reg("R15")))
				out:flush()
				last_pc = pc
			end
		end)
end
out:write("J0XP write watch started\n")
out:flush()
