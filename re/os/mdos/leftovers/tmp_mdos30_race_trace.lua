-- Temporary instruction trace for the KER0 tset/jr semaphore race.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_RACE_TRACE") or "/tmp/m40_mdos30_race.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local taps = {}
local releases = 0
local armed = false
local events = 0
local last_pc = -1

local function reg(name)
	return state[name] and state[name].value or 0
end

local function log(kind, extra)
	if events >= 300 then return end
	events = events + 1
	out:write(string.format(
		"%03d %-5s pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X " ..
		"r4=%04X r5=%04X r10=%04X r15=%04X %s\n",
		events, kind, reg("PC"), reg("FCW"), reg("R0"), reg("R1"),
		reg("R2"), reg("R3"), reg("R4"), reg("R5"), reg("R10"), reg("R15"),
		extra or ""))
	out:flush()
end

taps[#taps + 1] = data_space:install_write_tap(0x001568, 0x001569, "mdos_sem_race",
	function(offset, data, mask)
		local pc = reg("PC")
		if pc == 0x02094e and data == 0 then
			releases = releases + 1
			if releases >= 2 then armed = true end
		end
		if armed then
			log("SEMW", string.format("data=%04X mask=%04X", data, mask))
		end
	end)

local function install(first, last, name)
	taps[#taps + 1] = program:install_read_tap(first, last, name,
		function()
			if not armed then return end
			local pc = reg("PC")
			if pc ~= last_pc then
				last_pc = pc
				log("EXEC", "")
			end
		end)
end

install(0x020900, 0x020961, "mdos_sched_race")
install(0x021100, 0x0211a1, "mdos_nvi_race")
install(0x3b0c00, 0x3b1421, "mdos_fdu_race")

out:write("race trace started\n")
out:flush()
