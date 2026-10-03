-- TEMP read-only cold-boot provenance watch; uses the existing input harness.
local m = manager.machine
local cpu = m.devices[":cpu:uc042:maincpu"]
local dir = assert(os.getenv("M40_SERIES_DIR"))
local log = assert(io.open(dir .. "/flag-origin.log", "w"))
local sdr
for name,index in pairs(m.devices[":cpu:uc042:mmu"].items) do
    if name:match("m_sdr$") then sdr = emu.item(index) end
end
local function base(seg)
    return (sdr:read(seg*4)*256+sdr:read(seg*4+1))*256
end
local taps = {}
for name,space in pairs(cpu.spaces) do
 if not name:find("io") then
 taps[#taps+1] = space:install_write_tap(0,0x7fffff,"flag-origin",function(a,d,mask)
    if ((base((a>>16)&0x3f)+(a&0xffff)) & 0xfffffe) ~= base(0)+0x1760 then return end
    log:write(string.format("WRITE %s %.9f %06X %04X %04X pc=%06X",name,emu.time(),a,d,mask,cpu.state.PC.value))
    for n=0,15 do log:write(string.format(" R%d=%04X",n,cpu.state["R"..n].value)) end
    log:write("\n"); log:flush()
end)
 end
end
emu.register_frame_done(function() assert(taps) end)
dofile("scripts/lua/mame_bcos_state.lua")
