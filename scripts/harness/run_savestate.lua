-- At SAVE_T save the machine state as SAVE_NAME (in OUT/sta), then continue.
local m = manager.machine
local done = false
emu.register_frame_done(function()
    if done or emu.time() < tonumber(os.getenv("SAVE_T")) then return end
    done = true
    m:save(os.getenv("SAVE_NAME"))
end)
dofile(os.getenv("INNER"))
