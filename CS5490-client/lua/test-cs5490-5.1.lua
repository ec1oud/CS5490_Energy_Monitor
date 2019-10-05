-- Test functionality of the CS5490 Energy Measurement IC
-- Requires Lua 5.1, lua-rs232 patched to support 600 baud
-- see https://github.com/ec1oud/librs232
-- works on an Olimex RT5350F-OLinuXino-EVB with OpenWrt

local rs232 = require "luars232"
local bit = require "bit"
local socket = require "socket"
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

local function writeRegister(page, address, value)
        local cmd = string.char(bit.bor(page, 0x80), bit.bor(address, 0x40),
                        bit.band(0xff, value), bit.band(0xff, bit.rshift(value, 8)), bit.rshift(value, 16))
        out:write(string.format("write register %x %x value %x: sending %x %x %x %x %x\n", 
                page, address, value,  
                string.byte(cmd, 1), string.byte(cmd, 2), string.byte(cmd, 3), string.byte(cmd, 4), string.byte(cmd, 5)))
        print(string.byte(cmd, 1, 5))
        err, len = p:write(cmd, 100)
end

local function fixedPoint1dot23ToFloat(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
	if (bit.rshift(fp, 23) ~= 0) then
		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
	end
	return fp * (2.0 ^ -23.0)
--	return string.format("%f", value)
end

-- set port settings
assert(p:set_baud_rate(rs232.RS232_BAUD_600) == rs232.RS232_ERR_NOERROR)
assert(p:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
assert(p:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
assert(p:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
assert(p:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)

out:write(string.format("OK, port open with values '%s'\n", tostring(p)))

writeRegister(16, 32, 0xfff3e0) -- I DC offset calibration
writeRegister(16, 37, 0xd0000) -- I AC offset calibration
writeRegister(16, 34, 0xfe6000) -- V DC offset calibration
writeRegister(16, 57, 0x00001e) -- set Tsettle to 30 OWR samples
socket.sleep(0.5)
-- sendInstruction(0x01) -- reset
-- sendInstruction(0x03) -- wake up
sendInstruction(0x15) -- continuous conversion
local temp = readRegister(16, 27)
out:write(string.format("temperature %d.%d\n", bit.rshift(temp, 16), bit.band(temp, 0xFFFF)))
out:write(string.format("instantaneous current %f\n", fixedPoint1dot23ToFloat(readRegister(16, 2))))
out:write(string.format("instantaneous voltage %f\n", fixedPoint1dot23ToFloat(readRegister(16, 3))))
out:write(string.format("instantaneous active power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 4))))
out:write(string.format("active power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 5))))
out:write(string.format("RMS current %f\n", fixedPoint1dot23ToFloat(readRegister(16, 6))))
out:write(string.format("RMS voltage %f\n", fixedPoint1dot23ToFloat(readRegister(16, 7))))
out:write(string.format("reactive power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 14))))
out:write(string.format("peak current %f\n", fixedPoint1dot23ToFloat(readRegister(0, 37))))
out:write(string.format("peak voltage %f\n", fixedPoint1dot23ToFloat(readRegister(0, 36))))
out:write(string.format("apparent power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 20))))
out:write(string.format("power factor %f\n", fixedPoint1dot23ToFloat(readRegister(16, 21))))
out:write(string.format("total active power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 29))))
out:write(string.format("total apparent power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 30))))
out:write(string.format("total reactive power %f\n", fixedPoint1dot23ToFloat(readRegister(16, 31))))

assert(p:close() == rs232.RS232_ERR_NOERROR)

