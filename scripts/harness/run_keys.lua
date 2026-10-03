-- STEPS="t:@Name" tap key whose field name starts with Name; "t:^Name" with CONTROL;
-- "t:%Name" with SHIFT; "t:=text" natural-keyboard text. Screenshot 3 s after each step.
local m = manager.machine
if os.getenv("ISL") == "floppy" then
    for _, f in pairs(m.ioport.ports[":cpu:uc042:ISL"].fields) do f.user_value = 0 end
end
local base = os.getenv("OUT") .. "/"
local out = assert(io.open(base .. "events.log", "w"))
local screen = assert(m.screens[":slot3:go252:screen"])
-- "#2F" selects the key whose name contains "(2F)" (keys whose names hold ';').
local function find(prefix)
    local code = prefix:match("^#(%x%x)$")
    for tag, port in pairs(m.ioport.ports) do
        for name, f in pairs(port.fields) do
            if code and name:find("(" .. code:upper() .. ")", 1, true) then return f end
            if not code and name:sub(1, #prefix) == prefix then return f end
        end
    end
    error("no key " .. prefix)
end
local ctrl, shift = find("CONTROL"), find("SHIFT")
local ev = {}
local function add(t, fn, n) ev[#ev + 1] = {t, fn, n} end
local k = 0
for t, s in (os.getenv("STEPS") or ""):gmatch("([%d.]+):([^;]*)") do
    t = tonumber(t); k = k + 1
    local mod, name = s:sub(1, 1), s:sub(2)
    if mod == "!" then
        -- "!floppydisk2=/path/x.imd": load an image into that drive (disk swap);
        -- "!floppydisk2=-": eject.
        local inst, path = name:match("^(%w+)=(.+)$")
        add(t, function()
            for tag, img in pairs(m.images) do
                if img.instance_name == inst then
                    if path == "-" then img:unload() else img:load(path) end
                end
            end
        end, "image " .. name)
    elseif mod == "=" then
        add(t, function() m.natkeyboard:post(name) end, "type " .. name)
    else
        local f = find(name)
        local hold = (mod == "^") and ctrl or (mod == "%") and shift or nil
        if hold then add(t, function() hold:set_value(1) end, "hold " .. mod) end
        add(t + 0.2, function() f:set_value(1) end, name .. " down")
        add(t + 0.5, function() f:set_value(0) end, name .. " up")
        if hold then add(t + 0.7, function() hold:set_value(0) end, "release " .. mod) end
    end
    local tag = string.format("k%02d_%s", k, (mod .. name):gsub("[^%w]", "_"))
    add(t + 3, function() screen:snapshot(base .. tag .. ".png") end, "shot " .. tag)
end
local step = tonumber(os.getenv("SHOT_STEP") or "5")
for t = step, tonumber(os.getenv("RUN_SECONDS") or "200"), step do
    add(t, function() screen:snapshot(base .. string.format("s_%06.1f.png", t)) end, "shot")
end
table.sort(ev, function(a, b) return a[1] < b[1] end)
local n = 1
emu.register_frame_done(function()
    while n <= #ev and emu.time() >= ev[n][1] do
        ev[n][2](); out:write(string.format("t=%.2f %s\n", emu.time(), ev[n][3])); out:flush(); n = n + 1
    end
end)
