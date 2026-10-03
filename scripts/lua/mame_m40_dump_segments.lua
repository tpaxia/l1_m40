-- Dump selected M40 logical segments after the diagnostic disk has booted.
--
-- Environment:
--   M40_DUMP_DELAY    seconds to wait before dumping, default 12
--   M40_DUMP_DIR      output directory, default /tmp
--   M40_DUMP_SEGMENTS comma-separated hex segments, default 01,1d,1e,21
--   M40_KEYS          optional natural-keyboard string to post before dumping
--   M40_KEY_DELAY     seconds to wait before posting keys, default 0
--   M40_POST_KEY_WAIT seconds to wait after posting keys before dumping, default 2

local delay = tonumber(os.getenv("M40_DUMP_DELAY") or "12.0")
local out_dir = os.getenv("M40_DUMP_DIR") or "/tmp"
local segs = os.getenv("M40_DUMP_SEGMENTS") or "01,1d,1e,21"
local keys = os.getenv("M40_KEYS") or ""
local key_delay = tonumber(os.getenv("M40_KEY_DELAY") or "0")
local post_key_wait = tonumber(os.getenv("M40_POST_KEY_WAIT") or "2")

local cpu = manager.machine.devices[":cpu:uc042:maincpu"] or manager.machine.devices[":maincpu"]
assert(cpu, "M40 CPU device not found")
local program = cpu.spaces["program"]

local function parse_segments(text)
	local result = {}
	for item in string.gmatch(text, "([^,]+)") do
		result[#result + 1] = tonumber(item, 16)
	end
	return result
end

local function dump_segment(seg)
	local path = string.format("%s/m40_seg_%02x.bin", out_dir, seg)
	local f = assert(io.open(path, "wb"))
	for off = 0, 0xffff do
		f:write(string.char(program:read_u8((seg << 16) | off)))
	end
	f:close()
	print(string.format("dumped segment %02x to %s", seg, path))
end

if keys ~= "" then
	emu.wait(key_delay)
	local i = 1
	while i <= #keys do
		-- {WAIT:sec} token pauses for `sec` seconds (float ok) for multi-step nav
		local wsec = keys:match("^{WAIT:([%d%.]+)}", i)
		if wsec then
			emu.wait(tonumber(wsec))
			i = i + #("{WAIT:" .. wsec .. "}")
		else
			local ch = keys:sub(i, i)
			if ch == "\\" and keys:sub(i + 1, i + 1) == "n" then
				manager.machine.natkeyboard:post("\n")
				i = i + 2
			else
				manager.machine.natkeyboard:post(ch)
				i = i + 1
			end
			emu.wait(0.05)
		end
	end
	emu.wait(post_key_wait)
else
	emu.wait(delay)
end

for _, seg in ipairs(parse_segments(segs)) do
	dump_segment(seg)
end
manager.machine:exit()
