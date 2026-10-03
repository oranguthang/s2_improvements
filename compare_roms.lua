#!/usr/bin/env lua

local clownmd5 = require "build_tools.lua.clownmd5"

if #arg ~= 2 then
	io.stderr:write("Usage: lua compare_roms.lua <baseline.bin> <ported.bin>\n")
	os.exit(false)
end

local function read_binary(path)
	local file, error_message = io.open(path, "rb")
	if not file then
		io.stderr:write(error_message .. "\n")
		os.exit(false)
	end
	local bytes = file:read("*a")
	file:close()
	return bytes
end

local function hex_hash(path)
	return (clownmd5.HashFile(path):gsub(".", function(byte)
		return string.format("%02x", byte:byte())
	end))
end

local baseline = read_binary(arg[1])
local ported = read_binary(arg[2])
print(string.format("Baseline: %d bytes, MD5 %s", #baseline, hex_hash(arg[1])))
print(string.format("Ported:   %d bytes, MD5 %s", #ported, hex_hash(arg[2])))

local different = math.abs(#baseline - #ported)
local first_difference
for i = 1, math.min(#baseline, #ported) do
	if baseline:byte(i) ~= ported:byte(i) then
		different = different + 1
		first_difference = first_difference or (i - 1)
	end
end
if not first_difference and #baseline ~= #ported then
	first_difference = math.min(#baseline, #ported)
end

if baseline == ported then
	print("PASS: ROMs are byte-for-byte identical (0 differing bytes).")
	os.exit(true)
end

print(string.format("FAIL: %d differing bytes; first difference at offset $%X.", different, first_difference))
os.exit(false)
