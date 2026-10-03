for tag, dev in pairs(manager.machine.devices) do
	print("DEV " .. tag)
	for name, space in pairs(dev.spaces or {}) do print(" SPACE " .. name) end
	for name, region in pairs(dev.memregions or {}) do print(" REGION " .. name .. " bytes=" .. region.size) end
	for name, share in pairs(dev.memshares or {}) do print(" SHARE " .. name .. " bytes=" .. share.size) end
end
manager.machine:exit()
