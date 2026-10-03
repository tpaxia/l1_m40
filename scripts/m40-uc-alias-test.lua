-- Isolated test only: exercise all UC VIENO aliases, then restore its state.
local uc = assert(manager.machine.devices[":cpu:uc042"])
local cpu = assert(manager.machine.devices[":cpu:uc042:maincpu"])
local io_space = assert(cpu.spaces["io_std"])
local gate
for name, index in pairs(uc.items) do
    if name:match("/m_arb_vieno$") then gate = emu.item(index) end
end
assert(gate, "VIENO saved item missing")
local original = gate:read(0)
for alias = 0, 15 do
    local base = 0xf000 | (alias << 8)
    for _, enabled in ipairs({false, true}) do
        io_space:write_u8(base | (enabled and 0x8c or 0x84), 0)
        assert(gate:read(0) == (enabled and 1 or 0), string.format("gate alias %04X failed", base))
        for read_alias = 0, 15 do
            local status = io_space:read_u8(0xf081 | (read_alias << 8))
            assert((status & 8) == (enabled and 8 or 0), "VIENO read alias failed")
        end
    end
end
io_space:write_u8(original ~= 0 and 0xff8c or 0xff84, 0)
print("PASS UC VIENO: 16 write aliases x 16 read aliases, enable and disable")
local function saved(dev, suffix)
    for name, index in pairs(dev.items) do
        if name:match("/" .. suffix .. "$") then return emu.item(index) end
    end
    error("missing saved item " .. suffix)
end
-- Inject pending-source fixtures, not disk commands, in this isolated run.
local pending = saved(manager.machine.devices[":l1bus"], "m_vi_state")
local irq_state = saved(cpu, "m_irq_state")
local irq_req = saved(cpu, "m_irq_req")
local old_pending, old_req = pending:read(0), irq_req:read(0)
local old_fcw = cpu.state["FCW"].value
cpu.state["FCW"].value = old_fcw & ~0x1800 -- fixture must not execute an ISR
assert(old_pending == 0, "test requires idle backplane")
pending:write(0, 1 << 2) -- GO280, level 2
io_space:write_u8(0xf084, 0)
emu.wait(0) -- input-line updates are deferred to scheduler synchronization
assert(irq_state:read(1) == 0, "FDU VI must be masked")
assert(pending:read(0) == 4, "masked FDU request must remain pending")
io_space:write_u8(0xff8c, 0)
emu.wait(0)
assert(irq_state:read(1) == 1, "FDU VI must appear on re-enable")
pending:write(0, 1 << 1) -- GO252, level 1b
io_space:write_u8(0xf084, 0)
emu.wait(0)
assert(irq_state:read(1) == 1, "level 1 must remain enabled")
pending:write(0, old_pending)
io_space:write_u8(original ~= 0 and 0xff8c or 0xff84, 0)
emu.wait(0)
irq_req:write(0, old_req)
cpu.state["FCW"].value = old_fcw
print("PASS VIENO masks FDU level 2, retains pending request, leaves level 1 enabled")

-- NV2-NV4 must be maskable again after being enabled. Exercise both pending
-- while masked and cancelling a not-yet-delivered interrupt. Cold isolated run.
local requests = saved(uc, "m_arb_req")
local releases = saved(uc, "m_arb_rel")
assert(requests:read(0) == 0, "NVI fixture requires no existing requests")
local old_releases = releases:read(0)
cpu.state["FCW"].value = old_fcw & ~0x1800
for channel = 1, 3 do
    local request, clear = 0xff88 + channel, 0xff80 + channel
    local mask, enable = 0xff84 + channel, 0xff8c + channel
    io_space:write_u8(enable, 0)
    io_space:write_u8(request, 0)
    io_space:write_u8(mask, 0)
    emu.wait(0.0001)
    assert(irq_state:read(0) == 0, "masked NVI must not assert")
    assert(requests:read(0) == (1 << channel), "mask discarded pending NVI")
    assert((io_space:read_u8(0xff81) & 0xf0) == (0x80 >> channel), "masked request readback lost")
    io_space:write_u8(enable, 0)
    emu.wait(0.0001)
    assert(irq_state:read(0) == 1, "unmask failed to deliver pending NVI")
    io_space:write_u8(clear, 0)
    emu.wait(0)
    assert(irq_state:read(0) == 0, "ack failed to clear NVI line")
end
for channel = 1, 3 do
    io_space:write_u8(((old_releases & (1 << (channel - 1))) ~= 0 and 0xff8c or 0xff84) + channel, 0)
end
io_space:write_u8(original ~= 0 and 0xff8c or 0xff84, 0)
emu.wait(0)
irq_req:write(0, old_req)
cpu.state["FCW"].value = old_fcw
print("PASS NV2-NV4 re-mask, pending readback, delayed IRQ cancellation, unmask and acknowledge")
manager.machine:exit()
