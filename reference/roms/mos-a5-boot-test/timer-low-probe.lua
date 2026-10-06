-- Provisional model probe: cancel a retained timer request when OUT1 is low.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local uc=m.devices[":cpu:uc042"]
local function item(suffix)
 for n,i in pairs(uc.items) do if n:match("/"..suffix.."$") then return emu.item(i) end end
 error(suffix)
end
local pending,output,gate=item("m_timer_pending"),item("m_timer_out1"),item("m_arb_vieno")
local count=0
local f=assert(io.open(os.getenv("OUT").."/intervention.txt","w"))
staleprobe=cpu.spaces.program:install_read_tap(0,0x7fff,"cancel-low-timer-request",function(a,d,mask)
 if pending:read(0)==1 and output:read(0)==0 then
  count=count+1
  pending:write(0,0)
  f:write(string.format("t=%.9f pc=%06x clear #%d while OUT1=0 VIENO=%d\n",emu.time(),cpu.state.PC.value,count,gate:read(0)));f:flush()
 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/next-failure.lua")
