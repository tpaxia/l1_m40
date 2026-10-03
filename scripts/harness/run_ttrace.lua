-- Time-window CPU trace: trace to OUT/trace.txt between TR_FROM and TR_TO seconds.
local HERE = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
local m = manager.machine
local a, b = tonumber(os.getenv("TR_FROM")), tonumber(os.getenv("TR_TO"))
local state = 0
emu.register_periodic(function()
    local t = emu.time()
    if state == 0 and t >= a then
        m.debugger:command("trace " .. os.getenv("OUT") .. "/trace.txt,,noloop"); state = 1
    elseif state == 1 and t >= b then
        m.debugger:command("trace off"); state = 2
    end
end)
dofile(HERE .. "run_keys.lua")
