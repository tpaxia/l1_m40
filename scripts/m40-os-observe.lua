-- Set the physical IPL switch, then use the saved-state observer (no overrides).
for name, field in pairs(manager.machine.ioport.ports[":cpu:uc042:ISL"].fields) do
    if name == "Console IPL Switch" then field.user_value = 0 end
end
local frames = 0
emu.register_frame_done(function()
    frames = frames + 1
    if frames == 3 then
        local value = manager.machine.ioport.ports[":cpu:uc042:ISL"]:read() & 2
        print(string.format("IPL switch bits: %02X", value))
        assert(value == 0, "ISL2 not selected")
    end
end)
dofile("scripts/lua/mame_bcos_state.lua")
