-- Temporary probe for J0XP module allocation and the post-load copy.

dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_m40_diag_trace.lua")

local path = os.getenv("M40_ALLOC_TRACE") or "/tmp/m40_mdos30_alloc.log"
local out = assert(io.open(path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local program = cpu.spaces["program"]
local taps = {}
local wanted = {
	[0x0306e8] = "module",
	[0x030716] = "before_load",
	[0x030718] = "after_load",
	[0x03072a] = "after_size",
	[0x030758] = "iteration_done",
	[0x2200d8] = "copy_setup",
	[0x2200f4] = "copy",
}
local last_pc = -1
local copy_logged = false

local function reg(name)
	return state[name] and state[name].value or 0
end

local function log_pc(pc)
	out:write(string.format(
		"%-14s pc=%08X fcw=%04X " ..
		"r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X " ..
		"r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X " ..
		"r12=%04X r13=%04X r14=%04X r15=%04X\n",
		wanted[pc], pc, reg("FCW"),
		reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"),
		reg("R8"), reg("R9"), reg("R10"), reg("R11"),
		reg("R12"), reg("R13"), reg("R14"), reg("R15")))
	out:flush()
end

local function install(first, last, name)
	taps[#taps + 1] = program:install_read_tap(first, last, name,
		function()
			local pc = reg("PC")
			if pc == 0x2200f4 and copy_logged then
				return
			end
			if wanted[pc] and pc ~= last_pc then
				log_pc(pc)
				if pc == 0x2200f4 then
					copy_logged = true
				end
				last_pc = pc
			elseif not wanted[pc] then
				last_pc = -1
			end
		end)
end

install(0x0306e8, 0x03075b, "mdos_alloc")
install(0x2200d8, 0x2200f7, "mdos_copy")
out:write("allocation trace started\n")
out:flush()
