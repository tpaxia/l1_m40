-- Temporary write trace for the KER0 scheduler lock and run queues.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_QUEUE_TRACE") or "/tmp/m40_mdos30_queue.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local data_space = cpu.spaces["data"]
local taps = {}

local function reg(name)
	return state[name] and state[name].value or 0
end

taps[#taps + 1] = data_space:install_write_tap(0x001568, 0x0015a7, "mdos_run_queues",
	function(offset, data, mask)
		if offset == 0x001568 and reg("PC") == 0x020920 then
			return
		end
		out:write(string.format(
			"QW pc=%08X fcw=%04X addr=%08X data=%04X mask=%04X " ..
			"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r10=%04X r15=%04X\n",
			reg("PC"), reg("FCW"), offset, data, mask,
			reg("R0"), reg("R1"), reg("R2"), reg("R3"),
			reg("R4"), reg("R5"), reg("R10"), reg("R15")))
		out:flush()
	end)

out:write("scheduler queue write trace started\n")
out:flush()
