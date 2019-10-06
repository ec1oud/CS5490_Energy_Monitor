-- Test functionality of the CS5490 Energy Measurement IC
-- Requires Lua 5.1, lua-rs232 patched to support 600 baud
-- see https://github.com/ec1oud/librs232
-- works on an Olimex RT5350F-OLinuXino-EVB with OpenWrt

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
-- sendInstruction(0x01) -- reset
-- sendInstruction(0x03) -- wake up
chip.sendInstruction(0x15) -- continuous conversion
out:write(string.format("temperature %f\n", chip.readRegisterFixed16dot16(16, 27)))
out:write(string.format("instantaneous current %f\n", chip.readRegisterFixed1dot23(16, 2)))
out:write(string.format("instantaneous voltage %f\n", chip.readRegisterFixed1dot23(16, 3)))
out:write(string.format("instantaneous active power %f\n", chip.readRegisterFixed1dot23(16, 4)))
out:write(string.format("active power %f\n", chip.readRegisterFixed1dot23(16, 5)))
out:write(string.format("RMS current %f\n", chip.readRegisterFixed1dot23(16, 6)))
out:write(string.format("RMS voltage %f\n", chip.readRegisterFixed1dot23(16, 7)))
out:write(string.format("reactive power %f\n", chip.readRegisterFixed1dot23(16, 14)))
out:write(string.format("peak current %f\n", chip.readRegisterFixed1dot23(0, 37)))
out:write(string.format("peak voltage %f\n", chip.readRegisterFixed1dot23(0, 36)))
out:write(string.format("apparent power %f\n", chip.readRegisterFixed1dot23(16, 20)))
out:write(string.format("power factor %f\n", chip.readRegisterFixed1dot23(16, 21)))
out:write(string.format("total active power %f\n", chip.readRegisterFixed1dot23(16, 29)))
out:write(string.format("total apparent power %f\n", chip.readRegisterFixed1dot23(16, 30)))
out:write(string.format("total reactive power %f\n", chip.readRegisterFixed1dot23(16, 31)))
assert(chip:close() == 0)
