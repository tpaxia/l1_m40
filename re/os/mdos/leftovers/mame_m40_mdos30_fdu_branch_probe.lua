-- Focused probe for the MDOS30 resident FDU completion path.
--
-- This wraps the normal MDOS slot probe and adds periodic state snapshots when
-- execution reaches the FDU ISR branch that decides whether the outstanding
-- request has completed.

dofile("/Users/paxia/Projects/L1_M30_M40/re/mame_m40_mdos30_slot_probe.lua")

local out_path = os.getenv("M40_BRANCH_TRACE") or "/tmp/m40_mdos30_fdu_branch.log"
local out = assert(io.open(out_path, "w"))

local cpu = manager.machine.devices[":maincpu"]
local data_space = cpu.spaces["data"]
local state = cpu.state

local seen = {}

local function reg(name)
	return state[name] and state[name].value or 0
end

local function log(fmt, ...)
	out:write(string.format(fmt, ...) .. "\n")
	out:flush()
end

local function rb(seg, off)
	return data_space:read_u8((seg << 16) | off)
end

local function rw(seg, off)
	return (rb(seg, off) << 8) | rb(seg, off + 1)
end

local function snapshot(label)
	local pc = reg("PC")
	local key = string.format("%s:%08X:%04X:%04X:%04X:%04X:%02X:%02X",
		label, pc, reg("R0"), reg("R2"), reg("R5"), reg("R6"), rb(0x00, 0x225f + 0xd), rb(0x00, 0x225f + 0xf))
	if seen[key] then
		return
	end
	seen[key] = true

	log("%s pc=%08X fcw=%04X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r8=%04X r9=%04X r10=%04X r11=%04X r12=%04X r13=%04X r14=%04X r15=%04X",
		label, pc, reg("FCW"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R8"), reg("R9"),
		reg("R10"), reg("R11"), reg("R12"), reg("R13"), reg("R14"), reg("R15"))

	log("STATE pc=%08X fdublk[16..2f]=%04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X",
		pc,
		rw(0x00, 0x225f + 0x16), rw(0x00, 0x225f + 0x18),
		rw(0x00, 0x225f + 0x1a), rw(0x00, 0x225f + 0x1c),
		rw(0x00, 0x225f + 0x1e), rw(0x00, 0x225f + 0x20),
		rw(0x00, 0x225f + 0x22), rw(0x00, 0x225f + 0x24),
		rw(0x00, 0x225f + 0x26), rw(0x00, 0x225f + 0x28),
		rw(0x00, 0x225f + 0x2a), rw(0x00, 0x225f + 0x2c),
		rw(0x00, 0x225f + 0x2e))
end

emu.register_periodic(function()
	local pc = reg("PC")
	if pc == 0x003b0d2a then
		snapshot("ISR-PRE-BUSY")
	elseif pc == 0x003b0d32 then
		snapshot("ISR-PRE-MASK")
	elseif pc == 0x003b0d3a then
		snapshot("ISR-BIT")
	elseif pc == 0x003b0d40 then
		snapshot("ISR-COMPLETE")
	elseif pc == 0x003b0d5e then
		snapshot("ISR-NOT-COMPLETE")
	elseif pc == 0x003b07c4 then
		snapshot("DISPATCH-RETURN")
	end
end)

log("mdos30 fdu branch probe started")
