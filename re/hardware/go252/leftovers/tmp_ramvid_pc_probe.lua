local log_path = os.getenv("M40_TRACE_LOG") or "/tmp/ramvid_pc_probe.log"
local out = assert(io.open(log_path, "w"))
local cpu = manager.machine.devices[":maincpu"]
local state = cpu.state
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local dump_dir = os.getenv("M40_DUMP_DIR")

local function reg(name)
	return state[name] and state[name].value or 0
end

local function log(fmt, ...)
	out:write(string.format(fmt, ...) .. "\n")
	out:flush()
end

local function sample(label)
	log("%s pc=%08X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
		label,
		reg("PC"), reg("R0"), reg("R1"), reg("R2"), reg("R3"),
		reg("R4"), reg("R5"), reg("R6"), reg("R7"), reg("R14"), reg("R15"))
end

local function post_enter()
	manager.machine.natkeyboard:post_coded("{ENTER}")
end

log("ramvid pc probe")
emu.wait(45)
sample("before-enter")
post_enter()
emu.wait(4)
manager.machine.natkeyboard:post("1")
emu.wait(4)
manager.machine.natkeyboard:post("0")
emu.wait(4)
manager.machine.natkeyboard:post("1")
emu.wait(4)
manager.machine.natkeyboard:post("0")
emu.wait(4)
post_enter()
sample("after-load-command")
emu.wait(35)
sample("before-go")
manager.machine.natkeyboard:post("4")
emu.wait(4)
post_enter()
sample("after-go-key")

for i = 1, 60 do
	emu.wait(1)
	sample(string.format("post-go-%02d", i))
end

if dump_dir then
	for _, seg in ipairs({0x00, 0x03, 0x04, 0x1d, 0x21, 0x3d}) do
		local path = string.format("%s/m40_seg_%02x.bin", dump_dir, seg)
		local f = assert(io.open(path, "wb"))
		for off = 0, 0xffff do
			f:write(string.char(program:read_u8((seg << 16) | off)))
		end
		f:close()
		log("dumped seg=%02X path=%s", seg, path)
		local data_path = string.format("%s/m40_data_seg_%02x.bin", dump_dir, seg)
		local data_file = assert(io.open(data_path, "wb"))
		for off = 0, 0xffff do
			data_file:write(string.char(data_space:read_u8((seg << 16) | off)))
		end
		data_file:close()
		log("dumped data seg=%02X path=%s", seg, data_path)
	end
end
