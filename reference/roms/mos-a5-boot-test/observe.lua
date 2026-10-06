local m=manager.machine
local out=assert(io.open(os.getenv("OUT").."/states.txt","w"))
local cpu=m.devices[":cpu:uc042:maincpu"]
local screen=m.screens[":slot3:go252:screen"]
local nextshot=5
local taps={}
taps[1]=cpu.spaces.io:install_write_tap(0xffe0,0xffe3,"lamps",function(a,d,mask)
 out:write(string.format("lamp t=%.4f addr=%x data=%x mask=%x\n",emu.time(),a,d,mask));out:flush()
end)
emu.register_frame_done(function()
 if emu.time()>=nextshot then
 out:write(string.format("t=%.2f PC=%08x FCW=%04x\n",emu.time(),cpu.state.PC.value,cpu.state.FCW.value));out:flush()
 screen:snapshot(os.getenv("OUT")..string.format("/screen-%03d.png",nextshot))
 nextshot=nextshot+10
 end
end)
