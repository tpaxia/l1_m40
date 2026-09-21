-- TEMP input regression: inject field edges and read the keyboard I/O interface.
-- No CPU memory/register patches. Actual Windows key delivery needs a PC test.
local m = manager.machine
local dir = assert(os.getenv("M40_KEYMAP_TEST_DIR"))
local log = assert(io.open(dir .. "/result.log", "w"))
local rows = {
 {0x06,0x01,0x04,0x07,0x17,0x1d,0x1e,0x13,0x21,0x24,0x2e,0x2c,0x2b,0x31},
 {0x05,0x03,0x0c,0x08,0x1f,0x11,0x14,0x19,0x25,0x26,0x30,0x2a,0x36,0x37,0x35},
 {0x02,0x09,0x0f,0x0d,0x18,0x15,0x1b,0x1a,0x28,0x22,0x2f,0x34,0x38},
 {0x6e,0x0a,0x0b,0x0e,0x10,0x20,0x1c,0x16,0x27,0x23,0x2d,0x29,0x70,0x12,0x6f},
 {0x44,0x46,0x63,0x5b,0x53,0x4b,0x56,0x5a,0x3d,0x42,0x43,0x41,0x47,0x48,0x54,0x5c},
 {0x49,0x4f,0x50,0x4d,0x59,0x57,0x58,0x55,0x62,0x5f,0x60,0x5d,0x67,0x68,0x65,0x61},
 {0x52,0x3b,0x39,0x51,0x4c,0x3a,0x5e,0x4e,0x3c,0x4a,0x3e,0x66,0x64,0x40,0x3f}
}
local fields, sequences = {}, {}
for row,codes in ipairs(rows) do
 local port = assert(m.ioport.ports[":slot3:go252:keyboard:K" .. (row-1)])
 for _,field in pairs(port.fields) do
  for column,code in ipairs(codes) do
   if field.mask == (1 << (column-1)) and not fields[code] then
    -- Lua exposes case aliases for letter fields; enumerate each mask once.
    fields[code] = field
    sequences[code] = m.input:seq_to_tokens(field:input_seq("standard"))
    log:write(string.format("BIND %02X %s\n",code,sequences[code]))
   end
  end
 end
end
local alt
for _,field in pairs(m.ioport.ports[":slot3:go252:keyboard:HOSTALT"].fields) do
 if field.mask == 1 then alt = field end
end
assert(alt)
local ui_type = m.ioport:token_to_input_type("UI_TOGGLE_UI")
local ui_sequence = m.input:seq_to_tokens(m.ioport:type_seq(ui_type))
assert(ui_sequence:match("^KEYCODE_F12 NOT "), "UI toggle must be F12 without modifiers")
local snapshot = m.ioport:token_to_input_type("UI_SNAPSHOT")
assert(m.ioport:type_seq(snapshot).empty, "F12 screenshot conflict")
log:write("PASS UI toggle reserved: " .. ui_sequence .. "\n")
assert(sequences[0x02] == "KEYCODE_F9")
assert(sequences[0x37] == "")
assert(sequences[0x5a] == "KEYCODE_F8")
assert(sequences[0x5c] == "KEYCODE_INSERT")
assert(sequences[0x3b] == "KEYCODE_DEL")
assert(sequences[0x3f] == "KEYCODE_HOME")
assert(sequences[0x51] == "KEYCODE_END")
assert(sequences[0x4c] == "KEYCODE_PGUP")
assert(sequences[0x3a] == "KEYCODE_PGDN")
assert(sequences[0x70]:find("KEYCODE_LCONTROL") and sequences[0x70]:find("KEYCODE_RCONTROL"))
for _,seq in pairs(sequences) do
 assert(not seq:find("KEYCODE_SCRLOCK"), "UI key assigned to guest")
 assert(not seq:find("KEYCODE_F12"), "Mac UI key assigned to guest")
 assert(not seq:find("KEYCODE_LALT") and not seq:find("KEYCODE_RALT"), "Alt sent as guest key")
 assert(not seq:find("KEYCODE_LWIN") and not seq:find("KEYCODE_RWIN") and not seq:find("KEYCODE_MENU"))
end
local tests, active, got, frame, step, failed = {}, nil, {}, 0, 0, false
local function add(name,expected,actions)
 tests[#tests+1] = {name=name,expected=expected,actions=actions}
end
local function set(code,value) fields[code]:set_value(value) end
-- Every logical matrix input is still reachable without Alt (including via
-- natural input/custom assignments), and modifiers retain their break codes.
for _,codes in ipairs(rows) do for _,code in ipairs(codes) do
 local expected = {code}
 if code == 0x6e or code == 0x6f or code == 0x70 then expected[#expected+1] = code+8 end
 add(string.format("matrix %02X",code),expected,{[1]=function() set(code,1) end,[4]=function() set(code,0) end})
end end
local layer = {{0x02,0x37},{0x22,0x54},{0x0f,0x3d},{0x26,0x66},{0x1f,0x64},{0x0d,0x40},{0x09,0x5e},
 {0x28,0x52},{0x10,0x49},{0x1b,0x48},{0x31,0x06},{0x41,0x59},{0x67,0x68},{0x62,0x65}}
for _,pair in ipairs(layer) do
 for mods=0,3 do for reverse=0,1 do
  local expected = {}
  if mods & 1 ~= 0 then expected[#expected+1] = 0x6e end
  if mods & 2 ~= 0 then expected[#expected+1] = 0x70 end
  expected[#expected+1] = pair[2]
  if mods & 2 ~= 0 then expected[#expected+1] = 0x78 end
  if mods & 1 ~= 0 then expected[#expected+1] = 0x76 end
  add(string.format("Alt %02X -> %02X mods=%d alt-first-release=%d",pair[1],pair[2],mods,reverse),expected,{
   [1]=function() alt:set_value(1); if mods & 1 ~= 0 then set(0x6e,1) end end,
   [3]=function() if mods & 2 ~= 0 then set(0x70,1) end end,
   [5]=function() set(pair[1],1) end,
   [8]=function() if reverse == 1 then alt:set_value(0) else set(pair[1],0) end end,
   [10]=function() set(pair[1],0); alt:set_value(0) end,
   [12]=function() if mods & 2 ~= 0 then set(0x70,0) end end,
   [14]=function() if mods & 1 ~= 0 then set(0x6e,0) end end})
 end end
end
add("Alt alone",{}, {[1]=function() alt:set_value(1) end,[4]=function() alt:set_value(0) end})
add("Unassigned Alt+Q is silent",{}, {[1]=function() alt:set_value(1) end,
 [3]=function() set(0x03,1) end,[6]=function() alt:set_value(0) end,[9]=function() set(0x03,0) end})
local function hex(values)
 local s={}; for _,v in ipairs(values) do s[#s+1]=string.format("%02X",v) end
 return table.concat(s," ")
end
local testindex=0
local io = assert(m.devices[":cpu:uc042:maincpu"].spaces.io_std)
-- Complete the normal keyboard startup handshake so the unattended ROM's
-- repeated FC announcement does not interleave with the test keystrokes.
io:write_u8(0x1f02,0x00)
local ready = false
local tap = io:install_read_tap(0xf000,0xffff,"keymap-test-uart",function(address,data,mask)
 local register = address & 0xff
 if register == 0x20 then ready = ((data >> 8) & 5) == 5 end
 if register == 0x22 and ready then
  local byte = (data >> 8) & 0xff
  if active then got[#got+1]=byte else log:write(string.format("IDLE %02X\\n",byte)) end
  ready = false
 end
end)
emu.register_frame_done(function()
 frame=frame+1
 assert(tap)
 -- Poll the normal UC keyboard interface, acknowledging queued bytes.
 for i=1,16 do
  if (io:read_u8(0xf020) & 5) ~= 5 then break end
  io:read_u8(0xf022)
 end
 if frame < 60 then return end
 if not active then
  testindex=testindex+1; active=tests[testindex]; got={}; step=0
  if not active then
   log:write(string.format("RESULT %s %d cases\n",failed and "FAIL" or "PASS",#tests))
   log:close(); m:exit(); return
  end
 end
 step=step+1
 if active.actions[step] then active.actions[step]() end
 if step == 18 then
  local ok=hex(got)==hex(active.expected); if not ok then failed=true end
  log:write(string.format("%s %s expected=[%s] got=[%s]\n",ok and "PASS" or "FAIL",active.name,hex(active.expected),hex(got)))
  log:flush(); active=nil
 end
end)
