-- Passive MDOS control-flow sampler.
--
-- This deliberately reads CPU state only.  Reading through a CPU address
-- space from Lua invokes the live MMU handlers and can perturb the machine.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_PC_TRACE") or "/tmp/m40_mdos30_pc.log"
local out = assert(io.open(path, "w"))
local state = manager.machine.devices[":maincpu"].state
local last = ""

local function reg(name)
	return state[name] and state[name].value or 0
end

emu.register_periodic(function()
	local line = string.format(
		"pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X " ..
		"r4=%04X r5=%04X r6=%04X r7=%04X r8=%04X r9=%04X " ..
		"r10=%04X r11=%04X r12=%04X r13=%04X r14=%04X r15=%04X",
		reg("PC"), reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R8"), reg("R9"),
		reg("R10"), reg("R11"), reg("R12"), reg("R13"), reg("R14"), reg("R15"))
	if line ~= last then
		out:write(line .. "\n")
		out:flush()
		last = line
	end
end)

out:write("passive PC probe started\n")
out:flush()
