-- Isolated register-interface regression. Does not boot an OS.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local sio=cpu.spaces["io_spc"]
local function w(op,v) sio:write_u8(op*256,v) end
local function r(op) return sio:read_u8(op*256) end
local function select(s,d) w(1,s);w(0x20,d) end
local function pointer(s,d)
 assert(r(1)==s,string.format("SAR=%02x expected=%02x",r(1),s))
 if d then assert(r(0x20)==d,"DSC mismatch") end
end
local passes=0
for _,op in ipairs({0x0c,0x0d,0x0e,0x0f}) do
 local final=(op==0x0c) and 1 or 3
 for _,action in ipairs({"read","write"}) do
  for _,sar in ipairs({62,63}) do
   select(sar,final)
   if action=="read" then r(op) else w(op,0x5a) end
   pointer((sar+1)%64,(op==0x0c or op==0x0f) and 0 or nil)
   passes=passes+1
  end
 end
end
-- Full-table data integrity: write two different patterns without rewinding;
-- each pass must traverse every byte, then return to zero.
select(0,0)
for i=0,255 do w(0x0f,(i*73+19)%256) end
pointer(0,0)
for i=0,255 do assert(r(0x0f)==(i*73+19)%256,"full-table read mismatch") end
pointer(0,0)
for i=0,255 do w(0x0f,(i*31+203)%256) end
pointer(0,0)
for i=0,255 do assert(r(0x0f)==(i*31+203)%256,"second-pass read mismatch") end
pointer(0,0)
-- Non-SAR-incrementing descriptor command must not advance SAR.
select(63,3);w(0x0b,0xa5);pointer(63,0)
select(63,3);assert(r(0x0b)==0xa5);pointer(63,0)
print(string.format("PASS: %d command/read-write/boundary cases; two full-table patterns; non-incrementing command",passes))
m:exit()
