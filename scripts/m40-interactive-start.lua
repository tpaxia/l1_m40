-- Fast startup, then normal speed for human input. No keys or I/O injected.
-- Native bindings only: do not alias the main keyboard to the numeric keypad.
print("K02733 KITA: keypad * (49) acknowledges an input error; Right Ctrl (51) does not")
local switched = false
emu.register_frame_done(function()
    if not switched and emu.time() >= 90 then
        manager.machine.video.throttled = true
        switched = true
        print("BCOS interactive session: normal speed enabled")
    end
end)
