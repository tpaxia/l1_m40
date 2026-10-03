-- Observation-only timed screen/CPU-state capture for M40 boot transitions.
-- The output directory must already exist.

local output_dir = assert(os.getenv("M40_SERIES_DIR"), "M40_SERIES_DIR is required")
local times_text = os.getenv("M40_SERIES_TIMES") or "55,60,65,70,72,74,76,80,90,99"
local times = {}
for item in times_text:gmatch("[^,]+") do
    local value = assert(tonumber(item), "M40_SERIES_TIMES contains a non-number")
    assert(value >= 0, "M40_SERIES_TIMES values must be non-negative")
    table.insert(times, value)
end
table.sort(times)

local screen = assert(manager.machine.screens[":slot3:go252:screen"])
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local state = cpu.state
local out = assert(io.open(output_dir .. "/states.txt", "w"))
local elapsed = 0

for _, capture_time in ipairs(times) do
    assert(capture_time >= elapsed, "M40_SERIES_TIMES must be ordered")
    emu.wait(capture_time - elapsed)
    elapsed = capture_time
    local stem = string.format("%06.2f", capture_time)
    screen:snapshot(output_dir .. "/screen-" .. stem .. ".png")
    out:write(string.format("t=%8.2f PC=%08X FCW=%04X IRQ_REQ=%02X\n",
        capture_time,
        state["PC"].value,
        state["FCW"].value,
        state["IRQ_REQ"] and state["IRQ_REQ"].value or 0))
    out:flush()
end

out:close()
