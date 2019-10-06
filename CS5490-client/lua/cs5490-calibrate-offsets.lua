local socket = require "socket"
local string = require "string"
local port_name = "/dev/ttyS1"
local out = io.stderr
chip = require "cs5490"

local err = chip.open(port_name)
if err ~= "" then
	out:write(string.format("can't open serial port '%s', error: '%s'\n", port_name, err))
	return
end

out:write(string.format("initial config registers 0x%x 0x%x 0x%x\n",
	chip.readRegisterInt(0, 0),
	chip.readRegisterInt(0, 1),
	chip.readRegisterInt(16, 0)
	))
out:write(string.format("line to sample frequency ratio %f\n", chip.readRegisterFixed1dot23(16, 49)))
out:write(string.format("chip status 0x%x 0x%x\n", chip.readRegisterInt(0, 24), chip.readRegisterInt(0, 25)))
out:write(string.format("initial SYSgain 0x%x %f\n", chip.readRegisterInt(16, 60), 2 * chip.readRegisterFixed1dot23(16, 60)))
out:write(string.format("initial Igain 0x%x %f\n", chip.readRegisterInt(16, 33), 2 * chip.readRegisterFixed1dot23(16, 33)))
out:write(string.format("initial I DC offset 0x%x\n", chip.readRegisterInt(16, 32)))
out:write(string.format("initial I AC offset 0x%x\n", chip.readRegisterInt(16, 37)))
out:write(string.format("initial Vgain 0x%x %f\n", chip.readRegisterInt(16, 35), 2 * chip.readRegisterFixed1dot23(16, 35)))
out:write(string.format("initial V DC offset 0x%x\n", chip.readRegisterInt(16, 34)))

chip.writeRegister(16, 33, 0x400000) -- set Igain = 1.0
-- OWR = 4000 Hz
chip.writeRegister(16, 57, 0x001f40) -- set Tsettle to 2000 ms = 8000 OWR samples
chip.sendInstruction(0x26) -- DC offset calibration: both current and voltage
socket.sleep(2.5)
chip.writeRegister(16, 37, 0)
chip.sendInstruction(0x36) -- AC offset calibration: both current and voltage
socket.sleep(3)
out:write(string.format("I DC offset 0x%x\n", chip.readRegisterInt(16, 32)))
out:write(string.format("I AC offset 0x%x\n", chip.readRegisterInt(16, 37)))
out:write(string.format("V DC offset 0x%x\n", chip.readRegisterInt(16, 34)))
chip.writeRegister(16, 57, 0x00001e) -- set Tsettle to 30 OWR samples

assert(chip:close() == 0)
