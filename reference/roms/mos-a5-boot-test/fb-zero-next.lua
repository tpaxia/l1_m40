-- Diagnostic only: override GO363 common status FB with zero.
local cpu=manager.machine.devices[":cpu:uc042:maincpu"]
local statuslog=assert(io.open(os.getenv("OUT").."/fb-zero.txt","w"))
local statuscount=0
fbzerotap=cpu.spaces["io_std"]:install_read_tap(0x3ffa,0x3ffb,"go363-fb-zero",function(a,d,mask)
 if a==0x3ffa and (mask & 0x00ff)~=0 then
  statuscount=statuscount+1
  if statuscount<=20 then statuslog:write(string.format("t=%.9f PC=%06x original=%04x mask=%04x return=%04x\n",emu.time(),cpu.state.PC.value,d,mask,d & 0xff00));statuslog:flush() end
  return d & 0xff00
 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/timer-low-probe.lua")
local cpu=manager.machine.devices[":cpu:uc042:maincpu"]
local f=assert(io.open(os.getenv("OUT").."/boot-search.txt","w"))
local pcs={0x1f30,0x1f8e,0x1ffc,0x200e,0x126e,0x1282,0x095e,0x0968,0x0976,0x09ae,0x09ea,0x09ec,0x0af8,0x0b04,0x0f34,0x0f48,0x0fce,0x0fd0,0x11e8,0x11d4,0x121a,0x1ab4,0x20a8,0x20fa,0x2140,0x2692,0x367c,0x378a,0x3fd2,0x4070}
local watch={} for _,p in ipairs(pcs) do watch[p]=true end
local counts={}
boottap=cpu.spaces.program:install_read_tap(0,0x7fff,"boot-search",function(a,d,mask)
 if not watch[a] or emu.time()<25 then return end
 counts[a]=(counts[a] or 0)+1 if counts[a]>80 then return end
 f:write(string.format("t=%.9f a=%04x fcw=%04x",emu.time(),a,cpu.state.FCW.value))
 for n=0,15 do f:write(string.format(" r%d=%04x",n,cpu.state["R"..n].value)) end
 f:write("\n");f:flush()
end)
local iocount=0
bootio=cpu.spaces["io_std"]:install_read_tap(0x5000,0x50ff,"hd-read",function(a,d,mask)
 if emu.time()>25 and iocount<200 then iocount=iocount+1;f:write(string.format("IO t=%.9f pc=%04x a=%04x d=%04x mask=%04x\n",emu.time(),cpu.state.PC.value,a,d,mask));f:flush() end
end)

local f9log=assert(io.open(os.getenv("OUT").."/f9.txt","w"))
local n=0
f9tap=manager.machine.devices[":cpu:uc042:maincpu"].spaces["io_std"]:install_read_tap(0x3ff8,0x3ff9,"observe-f9",function(a,d,mask)
 n=n+1 if n<=20 then f9log:write(string.format("t=%.9f PC=%06x d=%04x mask=%04x\n",emu.time(),manager.machine.devices[":cpu:uc042:maincpu"].state.PC.value,d,mask));f9log:flush() end
end)
