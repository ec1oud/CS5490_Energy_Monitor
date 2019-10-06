local socket = require "socket"
local string = require "string"
local port_name = "/dev/ttyS1"
local out = io.stderr
local bit = require "bit"
chip = require "cs5490"

local err = chip.open(port_name)
if err ~= "" then
	out:write(string.format("can't open serial port '%s', error: '%s'\n", port_name, err))
	return
end

local function floatToFixedPoint1dot23(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
--~ 	if (bit.rshift(fp, 23) ~= 0) then
--~ 		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
--~ 	end
	return fp / (2.0 ^ -23.0)
--	return string.format("%f", value)
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
chip.writeRegister(16, 35, 0x400000) -- set Vgain = 1.0
chip.writeRegister(18, 63, 0x400000) -- set Vgain = 1.0
-- OWR = 4000 Hz
chip.writeRegister(16, 57, 0x001f40) -- set Tsettle to 2000 ms = 8000 OWR samples

-- let's calibrate at 3.3A using a 750W heater, using the 22Ω burden resistors
-- scale register could be 0.33 = 0x2a3d71 (although the datasheet says to use 0.6 * Ical / Imax)
-- (we can't actually read out 3.3 from the Irms register, so will have to multiply by 10 in cs5490-current.lua)
local calScale = bit.tobit(floatToFixedPoint1dot23(0.33))
out:write(string.format("setting calibration scale %x\n", calScale))
chip.writeRegister(18, 63, calScale) -- set calibration scale
socket.sleep(0.5)
out:write(string.format("calibration scale %f %x\n", chip.readRegisterFixed1dot23(18, 63), chip.readRegisterInt(18, 63)))

chip.sendInstruction(0x39) -- current gain calibration
socket.sleep(3.5)
out:write(string.format("calibrated Igain 0x%x %f\n", chip.readRegisterInt(16, 33), 2 * chip.readRegisterFixed1dot23(16, 33)))
-- I used trial and error to come up with 0x247400; this calibration results in 0x240c44
-- anyway cs5490-current.lua ends up saying about 3.3 when the current is actually about 3.3

chip.writeRegister(16, 57, 0x00001e) -- set Tsettle to 30 OWR samples
assert(chip:close() == 0)
