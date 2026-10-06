-- Read-only trace of the A.5 boot/error and VI-dispatch paths.
local m=manager.machine
local cpu=m.devices[":cpu:uc042:maincpu"]
local out=assert(io.open(os.getenv("OUT").."/failure.txt","w"))
local pcs={[0x1878]=true,[0x18f8]=true,[0x0738]=true,[0x0744]=true,[0x076c]=true,[0x0780]=true,[0x07d2]=true,[0x07e6]=true,[0x07f0]=true,[0x080e]=true,[0x0812]=true,[0x0858]=true}
local counts={}
local saved={}
for _,tag in ipairs({":cpu:uc042",":l1bus"}) do
 for name,index in pairs(m.devices[tag].items) do
  if name:match("/m_timer_pending$") or name:match("/m_timer_vector$") or name:match("/m_timer_out1$") or name:match("/m_arb_vieno$") or name:match("/m_acia_irq$") or name:match("/m_vi_state$") then
   saved[tag..":"..name]=emu.item(index)
  end
 end
end
nexttaps={}
nexttaps[1]=cpu.spaces.program:install_read_tap(0,0x1fff,"failure-pc",function(a,d,mask)
 if pcs[a] then
  counts[a]=(counts[a] or 0)+1
  if counts[a]<=8 then
   out:write(string.format("t=%.6f fetch=%04x PC=%06x FCW=%04x IRQV=%04x NSP=%04x",emu.time(),a,cpu.state.PC.value,cpu.state.FCW.value,cpu.state.IRQV.value,cpu.state.NSPOFF.value))
   for n=0,15 do out:write(string.format(" r%d=%04x",n,cpu.state["R"..n].value)) end
   for name,v in pairs(saved) do out:write(string.format(" %s=%x",name,v:read(0))) end
   out:write("\n");out:flush()
  end
 end
end)
nexttaps[2]=cpu.spaces["io_std"]:install_write_tap(0xff00,0xffff,"uc-io",function(a,d,mask)
 if a==0xff00 or a==0xff8c or a==0xffa0 or (a>=0xffc0 and a<=0xffc6 and cpu.state.PC.value>=0x0738 and cpu.state.PC.value<=0x0786) then
 out:write(string.format("t=%.6f io-write PC=%06x a=%04x d=%04x mask=%04x\n",emu.time(),cpu.state.PC.value,a,d,mask));out:flush()
 end
end)
dofile("/Users/paxia/Projects/L1_M30_M40/reference/roms/mos-a5-boot-test/observe-keys.lua")
