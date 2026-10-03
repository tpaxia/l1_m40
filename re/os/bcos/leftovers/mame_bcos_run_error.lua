-- TEMP: read-only snapshots and bounded trace; optional ordinary key input.
local m = manager.machine
-- Configuration inputs are not restored by a CPU saved state.
if os.getenv("BCOS_REPLAY_ISL2") then
    for _, field in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do field.user_value = 0 end
end
local dir = assert(os.getenv("BCOS_RUN_TRACE_DIR"))
local cpu = m.devices[":cpu:uc042:maincpu"]
local log = assert(io.open(dir .. "/trace.log", "w"))
local taps, frames, count = {}, 0, 0
-- TEMP opt-in real media-change replay, using only disposable image copies.
local media_step
if os.getenv("BCOS_MEDIA_SWAP") then
    media_step = dofile("re/os/bcos/leftovers/mame_bcos_media_swap.lua")(m, dir, log)
end
-- TEMP provenance watch: include every logical alias of the physical word.
local sdr
for name, index in pairs(m.devices[":cpu:uc042:mmu"].items) do
    if name:match("m_sdr$") then sdr = emu.item(index) end
end
if os.getenv("BCOS_WATCH_1760") then
  for space_name, space in pairs(cpu.spaces) do
   if not space_name:find("io") then
    taps[#taps+1] = space:install_write_tap(0,0x7fffff,"watch-1760",function(a,d,mask)
        local seg = (a >> 16) & 0x3f
        local base = (sdr:read(seg*4)*256 + sdr:read(seg*4+1))*256
        if ((base + (a & 0xffff)) & 0xfffffe) ~= 0x23d60 then return end
        log:write(string.format("WATCH1760 %s %.9f addr=%06X data=%04X mask=%04X pc=%06X",space_name,emu.time(),a,d,mask,cpu.state.PC.value))
        for n=0,15 do log:write(string.format(" R%d=%04X",n,cpu.state["R"..n].value)) end
        log:write("\n")
    end)
   end
  end
end
local key, retry, control, test_run, shift
local command_keys = {}
for tag, port in pairs(m.ioport.ports) do
    for name, field in pairs(port.fields) do
        if name == os.getenv("BCOS_RUN_KEY") then key = field end
        if name == "F16/F8 (5A)" then retry = field end
        if name == "CONTROL (70/78)" then control = field end
        if name == "SHIFT (6E/76)" then shift = field end
        if name == os.getenv("BCOS_TEST_RUN_KEY") then test_run = field end
        if name:match("^[A-Za-z]$") then command_keys[name:lower()] = field end
        if name == (os.getenv("BCOS_RUN_ENTER") or "Keypad ENTER (61)") then command_keys["\n"] = field end
        -- TEMP BASIC smoke test: ordinary keypad digits and physical Space.
        if name == "SPACE (12)" then command_keys[" "] = field end
        if tag == ":slot3:go252:keyboard:K5" then
            local digits = {[2]="7",[4]="8",[8]="9",[32]="4",[64]="5",[128]="6",[512]="1",[1024]="2",[2048]="3",[4096]="0"}
            if digits[field.mask] then command_keys[digits[field.mask]] = field end
        end
        if tag == ":slot3:go252:keyboard:K5" and field.mask == 0x400 then command_keys["2"] = field end
        if tag == ":slot3:go252:keyboard:K5" and field.mask == 0x200 then command_keys["1"] = field end
        if tag == ":slot3:go252:keyboard:K5" and field.mask == 0x800 then command_keys["3"] = field end
    end
end
if os.getenv("BCOS_RUN_KEY") then assert(key, "unknown test key") end
local command = os.getenv("BCOS_RUN_COMMAND") or ""
local line_gap = tonumber(os.getenv("BCOS_RUN_LINE_GAP")) or 0
local command_schedule, command_tick = {}, 220
for i=1,#command do
    command_schedule[command_tick] = {command:sub(i,i), 1}
    command_schedule[command_tick+6] = {command:sub(i,i), 0}
    command_tick = command_tick + 12 + (command:sub(i,i) == "\n" and line_gap or 0)
end
local stop_frame = tonumber(os.getenv("BCOS_RUN_FRAMES")) or (#command > 0 and 600 or 180)
for i=1,#command do assert(command_keys[command:sub(i,i):lower()], "unsupported command key") end
local function snapshot(stem)
    m.screens[":slot3:go252:screen"]:snapshot(dir .. "/" .. stem .. ".png")
    for _, tag in ipairs({":ram", ":cpu:uc042:mmu"}) do
        for name, index in pairs(m.devices[tag].items) do
            if name:match("m_pointer$") or name:match("m_sdr$") then
                local item = emu.item(index)
                local f = assert(io.open(dir .. "/" .. stem .. "-" .. name:match("([^/]+)$") .. ".bin", "wb"))
                f:write(item:read_block(0,item.size*item.count)); f:close()
            end
        end
    end
    log:write("SNAPSHOT " .. stem)
    for name, reg in pairs(cpu.state) do log:write(string.format(" %s=%X",name,reg.value)) end
    log:write("\n")
end
for name,s in pairs(cpu.spaces) do
    if name:find("io") then
        for _, direction in ipairs({"read", "write"}) do
            taps[#taps+1] = s["install_" .. direction .. "_tap"](s,0x1000,0x2fff,"run-" .. name .. direction,
                function(a,d,mask)
                    if (a & 0xff) ~= 0x80 and (a & 0xff) ~= 0xe6 then
                        log:write(string.format("IO %.9f %s %04X %04X %04X pc=%06X\n",emu.time(),direction,a,d,mask,cpu.state.PC.value))
                    end
                end)
        end
    end
end
taps[#taps+1] = cpu.spaces.program:install_read_tap(0,0x7fffff,"run-cpu",function(a,d,mask)
    if frames < 90 or frames >= (#command > 0 and 500 or 179) or count >= 180000 or a ~= cpu.state.PC.value then return end
    if (a >> 16) == 0x02 or (a >> 16) == 0x03 or (a >> 16) == 0x3b then return end
    count = count + 1
    log:write(string.format("CPU %.9f %06X %04X",emu.time(),a,d))
    for n=0,15 do log:write(string.format(" %04X",cpu.state["R"..n].value)) end
    log:write("\n")
end)
emu.register_frame_done(function()
    assert(taps)
    frames = frames + 1
    -- TEMP: insert utility media after state restoration so READY transitions
    -- belong to this run, not to the saved state's empty FD2.
    if frames == 10 and os.getenv("BCOS_REPLAY_FLOP2_INSERT") then
        assert(os.getenv("BCOS_REPLAY_FLOP2"))
        local utility_drive
        for _, image in pairs(m.images) do
            if image.brief_instance_name == "flop2" then utility_drive = image end
        end
        local err = assert(utility_drive):load(dir .. "/utility.imd")
        assert(not err, tostring(err))
        log:write(string.format("MEDIA %.9f FD2 utility inserted after restore\n", emu.time()))
    end
    if media_step then media_step(frames) end
    if frames == 1 then
        snapshot("before")
        -- DIAGNOSTIC ONLY: isolate the observed stale/expected volume mismatch.
        -- Changes only disposable replay RAM, never the source state or image.
        if os.getenv("BCOS_RUN_VOLUME_PROBE") then
            for name,index in pairs(m.devices[":ram"].items) do
                if name:match("m_pointer$") then
                    local ram = emu.item(index)
                    assert(ram:read_block(0x2d348,6) == "LOAD  ", "unexpected volume field")
                    for i=1,6 do ram:write(0x2d347+i,("RUN   "):byte(i)) end
                    log:write("DIAGNOSTIC RAM ONLY expected volume LOAD -> RUN at 1D:0848\n")
                end
            end
        end
    end
    local input_delay = media_step and 300 or 0
    if frames == 30 + input_delay and key then key:set_value(1) end
    if frames == 35 + input_delay and key then key:set_value(0) end
    if frames == 70 then snapshot("acknowledged") end
    if os.getenv("BCOS_RUN_RETRY") then
        if frames == 90 + input_delay then assert(retry):set_value(1); count = 0 end
        if frames == 95 + input_delay then retry:set_value(0) end
    end
    if frames == 180 then snapshot("prompt") end
    -- TEMP ordinary CONTROL+RUN chord, no BCOS flag/LED patches.
    if os.getenv("BCOS_TEST_RUN_KEY") then
        if frames == 90 then assert(control):set_value(1) end
        if frames == 110 then assert(test_run):set_value(1) end
        if frames == 116 then test_run:set_value(0) end
        if frames == 130 then control:set_value(0) end
        if os.getenv("BCOS_TEST_TOGGLE_OFF") then
            if frames == 150 then control:set_value(1) end
            if frames == 170 then test_run:set_value(1) end
            if frames == 176 then test_run:set_value(0) end
            if frames == 190 then control:set_value(0) end
        end
    end
    -- TEMP: exercise real configuration inputs, never patch BCOS flags.
    if frames == 190 and os.getenv("BCOS_RUN_SWITCHES") then
        local port = assert(m.ioport.ports[":slot3:go252:keyboard:KEYSWITCHES"])
        local value = assert(tonumber(os.getenv("BCOS_RUN_SWITCHES"), 16))
        for name, field in pairs(port.fields) do
            if name:match("^Key switch ") then
                field.user_value = value & field.mask
            end
        end
        log:write(string.format("CONFIG key switches requested %02X\n", value))
    end
    local event = command_schedule[frames]
    -- Set/release Shift before/after the letter scan, never rewrite guest data.
    local upcoming = command_schedule[frames + 2]
    if upcoming and upcoming[2] == 1 and upcoming[1]:match("[A-Z]") then assert(shift):set_value(1) end
    if event then command_keys[event[1]:lower()]:set_value(event[2]) end
    local previous = command_schedule[frames - 2]
    if previous and previous[2] == 0 and previous[1]:match("[A-Z]") then shift:set_value(0) end
    if frames == stop_frame then snapshot("after"); log:close(); m:exit() end
end)
