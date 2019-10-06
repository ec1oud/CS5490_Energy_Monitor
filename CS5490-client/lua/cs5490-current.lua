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

require "cs5490-calibration"
socket.sleep(0.5)

out:write(string.format("initial config registers 0x%x 0x%x 0x%x\n",
	chip.readRegisterInt(0, 0),
	chip.readRegisterInt(0, 1),
	chip.readRegisterInt(16, 0)
	))
out:write(string.format("calibrated Igain 0x%x\n", chip.readRegisterInt(16, 33)))
chip.sendInstruction(0x15) -- continuous conversion
while true do
	socket.sleep(0.9)
	out:write(string.format("RMS current 0x%x %f\n", chip.readRegisterInt(16, 6), currentScale * chip.readRegisterFixed0dot24(16, 6)))
end
