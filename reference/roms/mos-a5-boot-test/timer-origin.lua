-- Observation only: follow UC timer request and output transitions.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local uc=m.devices[":cpu:uc042"]
local function item(suffix)
 for n,i in pairs(uc.items) do if n:match("/"..suffix.."$") then return emu.item(i) end end
 error(suffix)
end
local pending,output,gate,vector=item("m_timer_pending"),item("m_timer_out1"),item("m_arb_vieno"),item("m_timer_vector")
local log=assert(io.open(os.getenv("OUT").."/timer-origin.txt","w"))
local last,lastio="","none"
local count=0
local function sample(why)
 local state=string.format("pending=%d out1=%d vieno=%d vector=%02x",pending:read(0),output:read(0),gate:read(0),vector:read(0))
 if state~=last and count<1500 then
  count=count+1
  log:write(string.format("t=%.9f pc=%06x %s %s lastio=%s\n",emu.time(),cpu.state.PC.value,why,state,lastio));log:flush();last=state
 end
end
timertaps={}
timertaps[1]=cpu.spaces.program:install_read_tap(0,0x7fff,"timer-state",function(a,d,mask) sample("fetch") end)
timertaps[2]=cpu.spaces["io_std"]:install_write_tap(0xf000,0xffff,"timer-command",function(a,d,mask)
 if (a&0xff)==0xc0 or (a&0xff)==0xc2 or (a&0xff)==0xc4 or (a&0xff)==0xc6 or (a&0xff)==0x40 or (a&0xff)==0x00 or (a&0xff)>=0x80 and (a&0xff)<=0x8e then
  sample("before-io")
  lastio=string.format("%.9f pc=%06x addr=%04x data=%04x mask=%04x",emu.time(),cpu.state.PC.value,a,d,mask)
  if (a&0xff)~=0xc6 or ((d&0xff)~=0x40) then log:write("WRITE "..lastio.."\n");log:flush() end
 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/observe-keys.lua")
