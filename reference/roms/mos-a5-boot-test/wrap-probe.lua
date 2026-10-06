-- Diagnostic experiment only: alter MMU counters, never ROM bytes.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local mmu=m.devices[":cpu:uc042:mmu"]
local function item(suffix)
 for name,index in pairs(mmu.items) do
  if name:match("/"..suffix.."$") then return emu.item(index) end
 end
 error("missing "..suffix)
end
local sar,dsc=item("m_sar"),item("m_dsc")
local out=assert(io.open(os.getenv("OUT").."/wrap-probe.txt","w"))
local pending=false
local presar,predsc=0,0
local changes=0
local function apply(reason)
 sar:write(0,0);dsc:write(0,0);changes=changes+1
 out:write(string.format("t=%.6f pc=%06x wrap %s #%d\n",emu.time(),cpu.state.PC.value,reason,changes));out:flush()
end
wraptaps={}
wraptaps[1]=cpu.spaces.program:install_read_tap(0,0x7fffff,"wrap-sync",function(a,d,mask)
 if pending then apply("write");pending=false end
 presar=sar:read(0);predsc=dsc:read(0)
end)
wraptaps[2]=cpu.spaces["io_spc"]:install_write_tap(0x0f00,0x0fff,"wrap-write",function(a,d,mask)
 if sar:read(0)==63 and dsc:read(0)==3 then pending=true end
end)
wraptaps[3]=cpu.spaces["io_spc"]:install_read_tap(0x0f00,0x0fff,"wrap-read",function(a,d,mask)
 if presar==63 and predsc==3 then apply("read") end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/observe-keys.lua")
