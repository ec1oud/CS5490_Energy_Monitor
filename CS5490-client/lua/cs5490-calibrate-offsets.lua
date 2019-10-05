local socket = require("socket")
local rs232 = require "luars232"
local bit = require "bit"
local string = require "string"
port_name = "/dev/ttyS1"
local out = io.stderr

-- open port
local e, p = rs232.open(port_name)
if e ~= rs232.RS232_ERR_NOERROR then
	-- handle error
	out:write(string.format("can't open serial port '%s', error: '%s'\n",
			port_name, rs232.error_tostring(e)))
	return
end

-- helper functions
local function sendInstruction(instruction)
	local cmd = string.char(bit.bor(instruction, 0xC0))
	err, len = p:write(cmd, 100)                                                                                       
        assert (err == rs232.RS232_ERR_NOERROR)                                                                              
        assert (len == 1)   
end

local function writeRegister(page, address, value)
	local cmd = string.char(bit.bor(page, 0x80), bit.bor(address, 0x40),
			bit.band(0xff, value), bit.band(0xff, bit.rshift(value, 8)), bit.rshift(value, 16))
	out:write(string.format("write register %x %x value %x: sending %x %x %x %x %x\n", 
		page, address, value,  
		string.byte(cmd, 1), string.byte(cmd, 2), string.byte(cmd, 3), string.byte(cmd, 4), string.byte(cmd, 5)))
	print(string.byte(cmd, 1, 5))
	err, len = p:write(cmd, 100)
end

local function readRegister(page, address)
	local cmd = string.char(bit.bor(page, 0x80), address)
	-- print("sending", string.byte(cmd, 1, 2))
	err, len = p:write(cmd, 100)
	assert (err == rs232.RS232_ERR_NOERROR)
	assert (len == 2)
	local err, b1, len = p:read(1, 100)
	assert(err == rs232.RS232_ERR_NOERROR)
	local err, b2, len = p:read(1, 100)
	assert(err == rs232.RS232_ERR_NOERROR)
	local err, b3, len = p:read(1, 100)
	assert(err == rs232.RS232_ERR_NOERROR)
	local ret = bit.bor(bit.lshift(string.byte(b3), 16), bit.lshift(string.byte(b2), 8), string.byte(b1))
	-- print("page", page, "address", address, "->", string.byte(b1), string.byte(b2), string.byte(b3), "->", ret)
	return ret
end

local function fixedPoint1dot23ToFloat(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
	if (bit.rshift(fp, 23) ~= 0) then
		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
	end
	return fp * (2.0 ^ -23.0)
--	return string.format("%f", value)
end

local function fixedPoint2dot22ToFloat(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
	if (bit.rshift(fp, 22) ~= 0) then
		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
	end
	return fp * (2.0 ^ -22.0)
end

-- set port settings
assert(p:set_baud_rate(rs232.RS232_BAUD_600) == rs232.RS232_ERR_NOERROR)
assert(p:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
assert(p:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
assert(p:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
assert(p:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)

out:write(string.format("OK, port open with values '%s'\n", tostring(p)))

out:write(string.format("initial config registers 0x%x 0x%x 0x%x\n", 
	readRegister(0, 0),
	readRegister(0, 1),
	readRegister(16, 0)
	))
out:write(string.format("line to sample frequency ratio %f\n", fixedPoint1dot23ToFloat(readRegister(16, 49))))
out:write(string.format("chip status 0x%x 0x%x\n", readRegister(0, 24), readRegister(0, 25)))
out:write(string.format("initial SYSgain 0x%x %f\n", readRegister(16, 60), 2 * fixedPoint1dot23ToFloat(readRegister(16, 60))))
out:write(string.format("initial Igain 0x%x %f\n", readRegister(16, 33), 2 * fixedPoint1dot23ToFloat(readRegister(16, 33))))
out:write(string.format("initial I DC offset 0x%x\n", readRegister(16, 32)))
out:write(string.format("initial I AC offset 0x%x\n", readRegister(16, 37)))
out:write(string.format("initial Vgain 0x%x %f\n", readRegister(16, 35), 2 * fixedPoint1dot23ToFloat(readRegister(16, 35))))
out:write(string.format("initial V DC offset 0x%x\n", readRegister(16, 34)))

writeRegister(16, 33, 0x400000) -- set Igain = 1.0
-- OWR = 4000 Hz
writeRegister(16, 57, 0x001f40) -- set Tsettle to 2000 ms = 8000 OWR samples
sendInstruction(0x26) -- DC offset calibration: both current and voltage
socket.sleep(2.5)
writeRegister(16, 37, 0)
sendInstruction(0x36) -- AC offset calibration: both current and voltage
socket.sleep(3)
out:write(string.format("I DC offset 0x%x\n", readRegister(16, 32)))
out:write(string.format("I AC offset 0x%x\n", readRegister(16, 37)))
out:write(string.format("V DC offset 0x%x\n", readRegister(16, 34)))

assert(p:close() == rs232.RS232_ERR_NOERROR)

