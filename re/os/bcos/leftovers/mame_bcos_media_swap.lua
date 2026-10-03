-- TEMP: observe READY/status and label across explicit LOAD/eject/RUN.
-- State C is already after the original failing swap; this tests recovery,
-- not a fresh initialization handoff. No guest RAM or controller writes.
return function(m, dir, log)
    local drive
    for _, image in pairs(m.images) do
        if image.brief_instance_name == "flop1" then drive = image end
    end
    assert(drive)
    local observed = {}
    for _, tag in ipairs({":slot4:go280:fdc", drive.device.tag, ":slot4:go280"}) do
        for name, index in pairs(m.devices[tag].items) do
            if name:match("ready") or name:match("st0") or name:match("irq")
                or name:match("interrupt") or name:match("pending") or name:match("main_phase") then
                observed[#observed+1] = {name=tag .. "/" .. name, item=emu.item(index)}
            end
        end
    end
    local ram
    for name, index in pairs(m.devices[":ram"].items) do
        if name:match("m_pointer$") then ram = emu.item(index) end
    end
    return function(frame)
        if frame == 10 then
            drive:unload()
            local err = drive:load(dir .. "/load.imd")
            assert(not err, tostring(err))
            log:write(string.format("MEDIA %.9f LOAD inserted\n", emu.time()))
        elseif frame == 70 then
            drive:unload()
            log:write(string.format("MEDIA %.9f EJECT; empty for 120 frames\n", emu.time()))
        elseif frame == 190 then
            local err = drive:load(dir .. "/run.imd")
            assert(not err, tostring(err))
            log:write(string.format("MEDIA %.9f RUN inserted\n", emu.time()))
        end
        for _, entry in ipairs(observed) do
            local values = {}
            for i=0,entry.item.count-1 do values[#values+1] = tostring(entry.item:read(i)) end
            local value = table.concat(values, ",")
            if value ~= entry.last then
                log:write(string.format("MEDIASTATE %.9f %s %s\n", emu.time(), entry.name, value))
                entry.last = value
            end
        end
        local expected = ram:read_block(0x2d348, 6)
        if expected ~= observed.expected then
            log:write(string.format("EXPECTED %.9f %q\n", emu.time(), expected))
            observed.expected = expected
        end
        log:flush()
    end
end
