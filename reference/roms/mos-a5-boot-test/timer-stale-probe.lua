-- Diagnostic only: clear exactly one stale timer request before enabling VI.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local uc=m.devices[":cpu:uc042"]
local function item(suffix)
 for n,i in pairs(uc.items) do if n:match("/"..suffix.."$") then return emu.item(i) end end
 error(suffix)
end
local pending,output,gate=item("m_timer_pending"),item("m_timer_out1"),item("m_arb_vieno")
local done=false
local f=assert(io.open(os.getenv("OUT").."/intervention.txt","w"))
staleprobe=cpu.spaces.program:install_read_tap(0x738,0x739,"clear-one-stale-request",function(a,d,mask)
 if not done then
  assert(pending:read(0)==1 and output:read(0)==0 and gate:read(0)==0,"unexpected fixture")
  pending:write(0,0);done=true
  f:write(string.format("t=%.9f cleared one pending timer request at 0738; OUT1=0 VIENO=0\n",emu.time()));f:flush()
 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/next-failure.lua")
