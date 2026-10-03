-- Read-only assertion of default image numbering, followed by boot observation.
local expected = {[0]="flop4", [1]="flop1", [2]="flop2", [3]="flop3"}
local images = {}
for _, image in pairs(manager.machine.images) do
    images[image.device.tag] = image
end
for unit=0,3 do
    local tag = ":slot4:go280:fdc:" .. unit .. ":8dsdd"
    local drive = assert(images[tag], tag)
    assert(drive.brief_instance_name == expected[unit], "unexpected image order: " .. tag)
    print(string.format("DRIVE_MAP %s = controller unit %d (%s)", drive.brief_instance_name, unit, tag))
end
dofile("/Users/paxia/Projects/L1_M30_M40/scripts/lua/mame_bcos_state.lua")
