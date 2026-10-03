-- Temporary instruction-flow probe for the post-load module dispatch.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_DISPATCH_TRACE") or "/tmp/m40_mdos30_dispatch.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local program = cpu.spaces["program"]
local taps = {}
local last_pc = -1

local function reg(name)
	return state[name] and state[name].value or 0
end

local function install(first, last, name)
	taps[#taps + 1] = program:install_read_tap(first, last, name,
		function()
			local pc = reg("PC")
			if pc ~= last_pc and
				((pc >= 0x22010e and pc <= 0x2201a7) or
				 (pc >= 0x030000 and pc <= 0x030080)) then
				out:write(string.format(
					"pc=%08X fcw=%04X " ..
					"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
					"r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
					"r12=%04X r13=%04X r14=%04X r15=%04X\n",
					pc, reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
					reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R8"), reg("R9"),
					reg("R10"), reg("R11"), reg("R12"), reg("R13"), reg("R14"), reg("R15")))
				out:flush()
				last_pc = pc
			end
		end)
end

install(0x22010e, 0x2201a7, "mdos_dispatch")
install(0x030000, 0x030081, "mdos_kio_entry")
out:write("dispatch trace started\n")
out:flush()
