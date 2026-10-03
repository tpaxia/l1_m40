-- Select floppy IPL, run the long boot unthrottled, then return to real time.
local machine = manager.machine
for name, field in pairs(machine.ioport.ports[":cpu:uc042:ISL"].fields) do
    if name == "Console IPL Switch" then field.user_value = 0 end
end

local switched = false
emu.register_frame_done(function()
    if not switched and emu.time() >= 90 then
        machine.video.throttled = true
        switched = true
        print("ESE interactive session: READY; normal speed enabled")
    end
end)
