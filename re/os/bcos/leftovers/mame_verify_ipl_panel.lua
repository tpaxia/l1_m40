-- Disposable configuration-only test; no media or guest-memory patches.
local machine = manager.machine
local target = machine.video.snapshot_target
local view = target.current_view
assert(view.name == "Screen with IPL selector status", view.name)
local item = assert(view.items:at(3), "IPL layout item missing")
local port = assert(machine.ioport.ports[":cpu:uc042:ISL"])
local field = assert(port.fields["Console IPL Switch"])
local original = field.user_value
local frame = 0
emu.register_frame_done(function()
    frame = frame + 1
    if frame == 1 then field.user_value = 0 end
    if frame == 3 then
        assert(item.element_state == 0, "floppy indicator mismatch")
        machine.screens[":slot3:go252:screen"]:snapshot(os.getenv("M40_SERIES_DIR") .. "/ipl-floppy.png")
        print("IPL_PANEL FLOPPY state=0 PASS")
        field.user_value = 2
    end
    if frame == 5 then
        assert(item.element_state == 1, "hard disk indicator mismatch")
        machine.screens[":slot3:go252:screen"]:snapshot(os.getenv("M40_SERIES_DIR") .. "/ipl-hd.png")
        print("IPL_PANEL HD state=1 PASS")
        field.user_value = original
        machine:exit()
    end
end)
