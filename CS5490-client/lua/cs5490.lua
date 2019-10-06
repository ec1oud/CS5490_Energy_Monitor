local socket = require "socket"
local rs232 = require "luars232"
local bit = require "bit"
local string = require "string"
local out = io.stderr
local p = 0
local M = {}

-- helper functions
local function fixedPoint0dot24ToFloat(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
	if (bit.rshift(fp, 24) ~= 0) then
		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
	end
	return fp * (2.0 ^ -24.0)
--	return string.format("%f", value)
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

local function fixedPoint16dot16ToFloat(fp)
	-- https://en.wikipedia.org/wiki/Q_%28number_format%29
	if (bit.rshift(fp, 16) ~= 0) then
		fp = bit.bor(fp, 0xff000000) -- sign-extend it from 24 to 32 bits
	end
	return fp * (2.0 ^ -16.0)
end

-- exported functions
function M.open(port_name)
	local e = rs232.RS232_ERR_NOERROR
	e, p = rs232.open(port_name)
	if e ~= rs232.RS232_ERR_NOERROR then
		return rs232.error_tostring(e)
	end
	assert(p:set_baud_rate(rs232.RS232_BAUD_600) == rs232.RS232_ERR_NOERROR)
	assert(p:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
	assert(p:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
	assert(p:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
	assert(p:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)
	out:write(string.format("OK, port open with values '%s'\n", tostring(p)))
	return ""
end

function M.close()
	local e = p:close()
	if e ~= rs232.RS232_ERR_NOERROR then
		out:write(string.format("can't close serial port, error: '%s'\n", rs232.error_tostring(e)))
		return e
	end
	return 0
end

function M.sendInstruction(instruction)
	local cmd = string.char(bit.bor(instruction, 0xC0))
	err, len = p:write(cmd, 100)
        assert (err == rs232.RS232_ERR_NOERROR)
        assert (len == 1)
end

function M.writeRegister(page, address, value)
	local cmd = string.char(bit.bor(page, 0x80), bit.bor(address, 0x40),
			bit.band(0xff, value), bit.band(0xff, bit.rshift(value, 8)), bit.rshift(value, 16))
--~ 	out:write(string.format("write register %x %x value %x: sending %x %x %x %x %x\n",
--~ 		page, address, value,
--~ 		string.byte(cmd, 1), string.byte(cmd, 2), string.byte(cmd, 3), string.byte(cmd, 4), string.byte(cmd, 5)))
--~ 	print(string.byte(cmd, 1, 5))
	err, len = p:write(cmd, 100)
end

function M.readRegisterInt(page, address)
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

function M.readRegisterFixed0dot24(page, address)
	return fixedPoint0dot24ToFloat(M.readRegisterInt(page, address))
end

function M.readRegisterFixed1dot23(page, address)
	return fixedPoint1dot23ToFloat(M.readRegisterInt(page, address))
end

function M.readRegisterFixed16dot16(page, address)
	return fixedPoint16dot16ToFloat(M.readRegisterInt(page, address))
end

return M
