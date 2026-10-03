-- M40 diagnostic trace helper.
--
-- Usage example:
--   M40_KEYS='\n' M40_TRACE_LOG=/tmp/m40_diag.log \
--   mame m40 -flop B.IMD -autoboot_script scripts/lua/mame_m40_diag_trace.lua ...
--
-- M40_KEYS is optional.  Characters are posted through MAME's natural keyboard,
-- so they use the driver's input ports rather than directly editing memory.
--
-- Experimental logical text snapshots:
--   M40_SCREEN_INTERVAL=1.0 logs the 80x25 segment-61 text view whenever it
--   changes. This reads through the CPU logical address space; it is useful only
--   when the diagnostic has a segment mapped to the framebuffer.
--
-- The script intentionally logs board I/O rather than patching execution.  This
-- makes it useful for both ROM IPL traces and disk-resident diagnostics once the
-- selector can be driven with M40_KEYS.

local log_path = os.getenv("M40_TRACE_LOG") or "/tmp/m40_diag_trace.log"
local keys = os.getenv("M40_KEYS") or ""
local key_delay = tonumber(os.getenv("M40_KEY_DELAY") or "8.0")
local inter_key_delay = tonumber(os.getenv("M40_INTER_KEY_DELAY") or "0.05")
local screen_interval = tonumber(os.getenv("M40_SCREEN_INTERVAL") or "0")
local screen_seg = tonumber(os.getenv("M40_SCREEN_SEG") or "3d", 16)
local screen_cols = tonumber(os.getenv("M40_SCREEN_COLS") or "80")
local screen_rows = tonumber(os.getenv("M40_SCREEN_ROWS") or "25")
local out = assert(io.open(log_path, "w"))

local function log(fmt, ...)
	out:write(string.format(fmt, ...) .. "\n")
	out:flush()
end

local cpu = manager.machine.devices[":cpu:uc042:maincpu"] or manager.machine.devices[":maincpu"]
assert(cpu, "M40 CPU device not found")
local io = cpu.spaces["io_std"]
local program = cpu.spaces["program"]
local data_space = cpu.spaces["data"]
local state = cpu.state
local taps = {}

local function read_tap(space, start, finish, name, callback)
	taps[#taps + 1] = space:install_read_tap(start, finish, name, callback)
end

local function write_tap(space, start, finish, name, callback)
	taps[#taps + 1] = space:install_write_tap(start, finish, name, callback)
end

local function pc()
	return state["PC"] and state["PC"].value or 0
end

local function cpu_reg(name)
	return state[name] and state[name].value or 0
end

local function bus_byte(addr, data, mask)
	if mask == 0xff00 then
		return (data >> 8) & 0xff
	elseif mask == 0x00ff then
		return data & 0xff
	end
	return data & 0xff
end

local function log_io(prefix, addr, data, mask)
	log("%s pc=%08X addr=%04X reg=%02X data=%02X raw=%04X mask=%04X",
		prefix, pc(), addr, addr & 0xff, bus_byte(addr, data, mask), data & 0xffff, mask & 0xffff)
end

local console_labels =
{
	[0x01] = "UC self-test",
	[0x02] = "RAM self-test",
	[0x03] = "unexpected interrupt vector",
	[0x04] = "no IPL controller / boot-error digit X",
	[0x05] = "waiting for first IPL attempt / boot-error digit Y",
	[0x08] = "waiting for IPL / no OS or media",
	[0x21] = "boot-error digits: peripheral/controller at slot 1",
	[0x44] = "IPL enumerating marker",
	[0x55] = "IPL booted marker or marker digit",
	[0xff] = "all digits/blank"
}

local function console_label(data)
	return console_labels[data & 0xff] or ""
end

local function screen_text()
	local lines = {}
	for row = 0, screen_rows - 1 do
		local chars = {}
		for col = 0, screen_cols - 1 do
			local off = (((row * screen_cols + col) << 1) + 1) & 0xffff
			local ch = program:read_u8((screen_seg << 16) | off)
			if ch < 0x20 or ch > 0x7e then
				ch = 0x20
			end
			chars[#chars + 1] = string.char(ch)
		end
		lines[#lines + 1] = table.concat(chars):gsub("%s+$", "")
	end
	return table.concat(lines, "\n")
end

local function log_screen(text)
	log("SCREEN BEGIN pc=%08X seg=%02X", pc(), screen_seg)
	for line in (text .. "\n"):gmatch("(.-)\n") do
		log("SCREEN |%s", line)
	end
	log("SCREEN END")
end

read_tap(io, 0x1000, 0x1fff, "go252_r", function(addr, data, mask)
	local reg = addr & 0xff
	if reg == 0x00 or reg == 0x02 or reg == 0x03 or reg == 0x20 or reg == 0x40 or reg == 0x42 or reg == 0x6a or reg == 0x80 or reg == 0xfe then
		log_io("GO252 R", addr, data, mask)
		if reg == 0x02 or reg == 0x03 then
			log("GO252 CTX pc=%08X r0=%04X r2=%04X r3=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
				pc(), cpu_reg("R0"), cpu_reg("R2"), cpu_reg("R3"), cpu_reg("R6"), cpu_reg("R7"), cpu_reg("R14"), cpu_reg("R15"))
		end
	end
end)

write_tap(io, 0x1000, 0x1fff, "go252_w", function(addr, data, mask)
	local reg = addr & 0xff
	if reg == 0x00 or reg == 0x02 or reg == 0x03 or reg == 0x20 or reg == 0x40 or reg == 0x42 or reg == 0x6a or reg == 0x6c or reg == 0x60 then
		log_io("GO252 W", addr, data, mask)
	end
end)

read_tap(io, 0x2000, 0x2fff, "go280_r", function(addr, data, mask)
	local reg = addr & 0xff
		if reg == 0x1d or reg == 0x1f or reg == 0x40 or reg == 0x42 or reg == 0x44 or reg == 0x46 or
				reg == 0x4a or reg == 0x50 or reg == 0x58 or reg == 0x5a or reg == 0x99 or reg == 0x9b or reg == 0x9d or
				reg == 0xed or reg == 0xef or reg == 0xf6 or reg == 0xf7 or reg == 0xff then
			log_io("GO280 R", addr, data, mask)
			if reg == 0xf6 or reg == 0xf7 or reg == 0x1d or reg == 0x1f then
				local r2 = cpu_reg("R2")
				log("GO280 CTX pc=%08X r0=%04X r1=%04X r2=%04X r2reg=%02X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
					pc(), cpu_reg("R0"), cpu_reg("R1"), r2, r2 & 0xff, cpu_reg("R3"), cpu_reg("R4"), cpu_reg("R5"), cpu_reg("R6"), cpu_reg("R7"), cpu_reg("R14"), cpu_reg("R15"))
			end
		end
	end)

write_tap(io, 0x2000, 0x2fff, "go280_w", function(addr, data, mask)
	local reg = addr & 0xff
		if reg == 0x1d or reg == 0x1f or reg == 0x40 or reg == 0x42 or reg == 0x44 or reg == 0x46 or
				reg == 0x58 or reg == 0x5a or reg == 0x99 or reg == 0x9b or reg == 0x9d or
				reg == 0xe7 or reg == 0xed or reg == 0xef or reg == 0xf6 or reg == 0xf7 or reg == 0xff then
			log_io("GO280 W", addr, data, mask)
			if reg == 0xf6 or reg == 0xf7 or reg == 0x58 or reg == 0x5a or reg == 0xe7 then
				local r2 = cpu_reg("R2")
				log("GO280 CTX pc=%08X r0=%04X r1=%04X r2=%04X r2reg=%02X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
					pc(), cpu_reg("R0"), cpu_reg("R1"), r2, r2 & 0xff, cpu_reg("R3"), cpu_reg("R4"), cpu_reg("R5"), cpu_reg("R6"), cpu_reg("R7"), cpu_reg("R14"), cpu_reg("R15"))
			end
		end
	end)

read_tap(io, 0xff20, 0xff23, "kdc_uc_r", function(addr, data, mask)
	log_io("UC-KDC R", addr, data, mask)
	if (addr & 0xff) == 0x22 then
		log("UC-KDC CTX pc=%08X r0=%04X r2=%04X r3=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
			pc(), cpu_reg("R0"), cpu_reg("R2"), cpu_reg("R3"), cpu_reg("R6"), cpu_reg("R7"), cpu_reg("R14"), cpu_reg("R15"))
	end
end)

write_tap(io, 0xff20, 0xff23, "kdc_uc_w", function(addr, data, mask)
	log_io("UC-KDC W", addr, data, mask)
end)

write_tap(io, 0xffe0, 0xffe1, "console_w", function(addr, data, mask)
	local label = console_label(data)
	if label ~= "" then
		log("CONSOLE pc=%08X data=%02X ; %s", pc(), data & 0xff, label)
	else
		log("CONSOLE pc=%08X data=%02X", pc(), data & 0xff)
	end
end)

local function install_diag_global_tap(space, name)
	if not space then
		return
	end
	write_tap(space, (0x04 << 16) | 0xa4a0, (0x04 << 16) | 0xa4af, name, function(addr, data, mask)
		log("DGLOBAL %s pc=%08X addr=%06X off=%04X data=%04X mask=%04X r0=%04X r1=%04X r2=%04X r3=%04X r4=%04X r5=%04X r6=%04X r7=%04X r14=%04X r15=%04X",
			name, pc(), addr, addr & 0xffff, data & 0xffff, mask & 0xffff,
			cpu_reg("R0"), cpu_reg("R1"), cpu_reg("R2"), cpu_reg("R3"),
			cpu_reg("R4"), cpu_reg("R5"), cpu_reg("R6"), cpu_reg("R7"),
			cpu_reg("R14"), cpu_reg("R15"))
	end)
end

if os.getenv("M40_DGLOBAL_TRACE") then
	install_diag_global_tap(data_space, "data")
end

log("trace started")
log("keys='%s' delay=%.3f inter=%.3f", keys:gsub("\n", "\\n"), key_delay, inter_key_delay)
log("screen interval=%.3f seg=%02X cols=%d rows=%d", screen_interval, screen_seg, screen_cols, screen_rows)

if keys ~= "" then
	emu.wait(key_delay)
	local i = 1
	while i <= #keys do
		local ch = keys:sub(i, i)
		if ch == "\\" and keys:sub(i + 1, i + 1) == "n" then
			log("KEY post {ENTER}")
			manager.machine.natkeyboard:post_coded("{ENTER}")
			i = i + 2
		elseif ch == "{" then
			local finish = keys:find("}", i + 1, true)
			if finish then
				local code = keys:sub(i + 1, finish - 1)
				local wait = code:match("^WAIT:([0-9.]+)$")
				if wait then
					log("KEY wait %s", wait)
					emu.wait(tonumber(wait) or 0)
				else
					log("KEY post {%s}", code)
					manager.machine.natkeyboard:post_coded("{" .. code .. "}")
				end
				i = finish + 1
			else
				log("KEY post %s", ch)
				manager.machine.natkeyboard:post(ch)
				i = i + 1
			end
		else
			log("KEY post %s", ch)
			manager.machine.natkeyboard:post(ch)
			i = i + 1
		end
		emu.wait(inter_key_delay)
	end
end

if screen_interval > 0 then
	local last_screen = ""
	local last_screen_time = 0
	emu.register_periodic(function()
		local now = os.clock()
		if now - last_screen_time < screen_interval then
			return
		end
		last_screen_time = now
		local text = screen_text()
		if text ~= last_screen then
			log_screen(text)
			last_screen = text
		end
	end)
end
