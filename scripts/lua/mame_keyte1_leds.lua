-- TEMP KEYTE1 observer: ordinary timed keys, host commands and real LED outputs.
local m = manager.machine
local dir = assert(os.getenv("M40_LED_DIR"))
local log = assert(io.open(dir .. "/leds.log", "w"))
local cpu = m.devices[":cpu:uc042:maincpu"]
local keyboard = m.devices[":slot3:go252:keyboard"]
local expected, seen, taps = {}, {}, {}
for space_name, space in pairs(cpu.spaces) do
    if space_name:find("io") then
        taps[#taps+1] = space:install_write_tap(0x1f02,0x1f03,"keyte-led-command",function(a,d,mask)
            local command = d & 0xff
            local index
            if command >= 5 and command <= 12 then index = (command - 5) // 2
            elseif command == 15 or command == 16 then index = 4 end
            if index then expected[index] = command & 1; seen[command] = true end
            log:write(string.format("COMMAND %.9f %02X pc=%06X\n",emu.time(),command,cpu.state.PC.value))
        end)
        taps[#taps+1] = space:install_read_tap(0x1f02,0x1f03,"keyte-key-code",function(a,d,mask)
            log:write(string.format("KEY %.9f %02X pc=%06X\n",emu.time(),d & 0xff,cpu.state.PC.value))
        end)
    end
end
local last, next_snapshot = {}, 120
local exit_keys = {}
for _, port in pairs(m.ioport.ports) do
    for name, field in pairs(port.fields) do
        if name == "F9/F1 (44)" then exit_keys[1] = field end
        if name == "top-right key (39)" then exit_keys[2] = field end
        if name == "PR ALL/NO PR (3F)" then exit_keys[3] = field end
    end
end
local exit_event = 1
local exit_schedule = {170,170.2,171,171.2,172,172.2,185,185.2,186,186.2,187,187.2}
emu.register_frame_done(function()
    assert(taps)
    if os.getenv("M40_KEYTE_ADVANCE") and exit_schedule[exit_event] and emu.time() >= exit_schedule[exit_event] then
        local key_index = ((exit_event-1) // 2) % 3 + 1
        assert(exit_keys[key_index]):set_value(exit_event % 2)
        exit_event = exit_event + 1
    end
    for i=0,4 do
        local value = keyboard.outputs["m40_kbd_led" .. i]:get()
        if expected[i] ~= nil then assert(value == expected[i], "LED command/output mismatch") end
        if value ~= last[i] then
            log:write(string.format("LED %.9f %d=%d\n",emu.time(),i,value)); last[i] = value
        end
    end
    if emu.time() >= next_snapshot then
        m.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. next_snapshot .. ".png")
        m:save(dir .. "/diagnostic.sta")
        next_snapshot = next_snapshot + 10
    end
    log:flush()
end)
dofile("scripts/lua/mame_m40_timed_keys.lua")
