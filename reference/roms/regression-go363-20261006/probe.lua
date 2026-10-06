-- The two local provisional changes; no ROM or guest RAM patches.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local f=assert(io.open(os.getenv("OUT").."/interventions.log","w"))
local counts={}
regression_taps={}
if os.getenv("PROVISIONAL")=="1" then
 regression_taps[1]=cpu.spaces.io_std:install_read_tap(0x3ff8,0x3ffb,"healthy-common-status",function(a,d,mask)
  if (a==0x3ff8 or a==0x3ffa) and (mask & 0xff)~=0 then
   counts[a]=(counts[a] or 0)+1
   if counts[a]<=100 then f:write(string.format("t=%.9f pc=%06x port=%04x original=%04x return=%04x\n",emu.time(),cpu.state.PC.value,a,d,d & 0xff00));f:flush() end
   return d & 0xff00
  end
 end)
 if os.getenv("CLEAR_TIMER")~="0" then
 local function item(suffix)
  for n,i in pairs(m.devices[":cpu:uc042"].items) do if n:match("/"..suffix.."$") then return emu.item(i) end end
  error(suffix)
 end
 local pending,output=item("m_timer_pending"),item("m_timer_out1")
 regression_taps[2]=cpu.spaces.program:install_read_tap(0,0x7fff,"clear-low-timer",function(a,d,mask)
  if pending:read(0)==1 and output:read(0)==0 then
   pending:write(0,0)
   f:write(string.format("t=%.9f pc=%06x clear stale UC timer\n",emu.time(),cpu.state.PC.value));f:flush()
  end
 end)
 end
end
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/observe-keys.lua")
-- DCOS displays its environment after the initial 70-second key event.
if os.getenv("OUT"):match("/dcos%-") then
 local posted=false
 emu.register_frame_done(function()
  if emu.time()>=110 and not posted then m.natkeyboard:post("\n");posted=true end
 end)
end
