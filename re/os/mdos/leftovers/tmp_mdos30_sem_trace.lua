-- Temporary probe for the post-boot KER0 scheduler semaphore and UC timer.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_SEM_TRACE") or "/tmp/m40_mdos30_sem.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local io = cpu.spaces["io_std"]
local taps = {}

local function reg(name)
	return state[name] and state[name].value or 0
end

local function log(kind, addr, data, mask)
	out:write(string.format(
		"%s pc=%08X fcw=%04X addr=%08X data=%04X mask=%04X " ..
		"r2=%04X r3=%04X r4=%04X r5=%04X\n",
		kind, reg("PC"), reg("FCW"), addr, data, mask,
		reg("R2"), reg("R3"), reg("R4"), reg("R5")))
	out:flush()
end

taps[#taps + 1] = data_space:install_write_tap(0x001568, 0x001569, "mdos_sem",
	function(offset, data, mask)
		log("SEMW", offset, data, mask)
	end)

taps[#taps + 1] = io:install_write_tap(0x00ff00, 0x00ffff, "mdos_uc_io",
	function(offset, data, mask)
		local addr = offset & 0xffff
		if addr == 0xff01 or (addr >= 0xff80 and addr <= 0xff8f) or
			(addr >= 0xffc0 and addr <= 0xffc7) then
			log("IOW", addr, data, mask)
		end
	end)

taps[#taps + 1] = io:install_read_tap(0x00ff80, 0x00ff8f, "mdos_arb_read",
	function(offset, data, mask)
		log("IOR", offset & 0xffff, data, mask)
	end)

out:write("scheduler semaphore probe started\n")
out:flush()
