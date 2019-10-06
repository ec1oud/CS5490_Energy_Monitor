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

chip.sendInstruction(0x15) -- continuous conversion
while true do
out:write(string.format("RMS current %f\n", chip.readRegisterFixed1dot23(16, 6)))
socket.sleep(0.9)
end
