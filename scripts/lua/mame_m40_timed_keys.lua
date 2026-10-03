-- Scheduled input and optional final screenshot, without memory taps or waits.
local keys = os.getenv("M40_KEYS") or ""
local spacing = tonumber(os.getenv("M40_INTER_KEY_DELAY") or "2")
local next_time = tonumber(os.getenv("M40_KEY_DELAY") or "70")
local pos = 1
local output = assert(io.open(os.getenv("M40_TRACE_LOG"), "w"))
local snapshot = os.getenv("M40_FINAL_SNAPSHOT")
local snapshot_time = tonumber(os.getenv("M40_FINAL_SNAPSHOT_TIME") or "229")
emu.register_frame_done(function()
    if snapshot and emu.time() >= snapshot_time then
        manager.machine.screens[":slot3:go252:screen"]:snapshot(snapshot)
        snapshot = nil
    end
    if pos > #keys or emu.time() < next_time then return end
    local token = keys:sub(pos, pos)
    if token == "\\" and keys:sub(pos + 1, pos + 1) == "n" then
        token = "{ENTER}"
        pos = pos + 2
    elseif token == "{" then
        local finish = assert(keys:find("}", pos, true))
        token = keys:sub(pos, finish)
        pos = finish + 1
    else
        pos = pos + 1
    end
    local delay = token:match("^{WAIT:([0-9.]+)}$")
    if delay then
        next_time = next_time + tonumber(delay) + spacing
    else
        output:write(string.format("KEY t=%.6f post %s\n", emu.time(), token))
        output:flush()
        manager.machine.natkeyboard:post_coded(token)
        next_time = next_time + spacing
    end
end)
