local fastpour = fastpour
local js = require("js")
local window = js.global
local Math = window.Math
local console = window.console
local function copy(src, seen, dst)
	if dst == nil then
		dst = {}
	end
	if seen == nil then
		seen = {}
	end
	seen[src] = dst
	for k, v in pairs(src) do
		local k2 = seen[k]
		if k2 ~= nil then
			k = k2
		elseif type(k) == "table" then
			k = copy(k, seen)
		end
		local v2 = seen[v]
		if v2 ~= nil then
			v = v2
		elseif type(v) == "table" then
			v = copy(v, seen)
		end
		dst[k] = v
	end
	return dst
end

local script = {}
script.__index = script
function script.new(client)
	return setmetatable({
		client = client,
		callbacks = {},
		strict = false,
	}, script)
end

script.env_spoof_lua51 = true
local function get_name(level)
	if level == nil then
		level = 2
	end
	level = level+1
	local info = debug.getinfo(level, "n")
	if info == nil then
		return "?"
	end
	return info.name
end
script._get_name = get_name
local function select_type(i, expected, ...)
	local value = select(i, ...)
	local actual = type(value)
	if select("#", ...) < i then
		actual = "no value"
	end
	if actual == expected then
		return true, value
	elseif type(expected) == "table" then
		for i=1, #expected do
			if expected[i] == actual then
				return true, value
			end
		end
		expected = expected[1]
	end
	return false
end
local function assert_select_type(i, expected, level, ...)
	local success, value = select_type(i, expected, ...)
	if success then
		return value
	end
	if level == nil then
		level = 2
	end
	level = level+1
	error(string.format("bad argument #%d to '%s' (expected %s, got %s)", i, get_name(), expected, actual), level)
end
script._assert_select_type = assert_select_type
local function assert_vararg(level, ...)
	if select("#", ...) == 0 then
		if level == nil then
			level = 2
		end
		level = level+1
		error(string.format("bad argument #1 to '%s' (value expected)", get_name()), level)
	end
	return ...
end
script._assert_vararg = assert_vararg
local function assert_argument(condition, i, str, level)
	if not condition then
		if level == nil then
			level = 2
		end
		level = level+1
		error(string.format("bad argument #%d to '%s' (%s)", i, get_name(), str), level)
	end
end
script._assert_argument = assert_argument
local weak_lookup = {
	number = 0,
	string = "",
}
script._weak_lookup = weak_lookup
function script:_weak_assert_select_type(i, expected, level, ...)
	local success, value = select_type(i, expected, ...)
	if not success then
		if self.strict then
			if level == nil then
				level = 2
			end
			level = level+1
			error(string.format("bad argument #%d to '%s' (expected %s, got %s)", i, get_name(), expected, actual), level)
		end
		if type(expected) == "table" then
			value = weak_lookup[expected[1]]
		else
			value = weak_lookup[expected]
		end
	end
	return value
end
function script:_weak_assert_vararg(level, ...)
	if not self.strict then
		return ...
	elseif select("#", ...) == 0 then
		if level == nil then
			level = 2
		end
		level = level+1
		error(string.format("bad argument #1 to '%s' (value expected)", get_name()), level)
	end
	return ...
end
function script:_weak_assert_argument(condition, i, str, level)
	if self.strict and not condition then
		if level == nil then
			level = 2
		end
		level = level+1
		error(string.format("bad argument #%d to '%s' (%s)", i, get_name(), str), level)
	end
end
function script._to_sane(n, level)
	if
		n == math.huge
		or n == -math.huge
		or n ~= n
	then
		return nil
	end
	return n
end
local cachebuster = fastpour.cachebuster
script.libraries = {
	--dofile("./api/parameters.lua"..cachebuster),
	dofile("./api/control.lua"..cachebuster),
	--dofile("./api/registry.lua"..cachebuster),
	--dofile("./api/vector.lua"..cachebuster),
	--dofile("./api/screen.lua"..cachebuster),
	--dofile("./api/sound.lua"..cachebuster),
	dofile("./api/misc.lua"..cachebuster),
	ui = dofile("./api/ui.lua"..cachebuster),
}
function script:env_init()
	local env = {}
	self.env = env
	-- TODO: whitelist, not blacklist
	copy(_ENV, nil, env)
	env._COPYRIGHT = nil
	env.debug = nil
	env.dofile = nil
	env.load = nil
	env.loadfile = nil
	env.os = nil
	env.package = nil
	env.require = nil
	env.fastpour = nil
	env.js = nil
	if self.env_spoof_lua51 then
		env._VERSION = "Lua 5.1"
		if pcall(collectgarbage, "count") then
			function env.gcinfo(...)
				return math.floor(collectgarbage("count"))
			end
		else
			env.collectgarbage = nil
		end
		function env.load(...)
			local func = assert_select_type(1, "function", nil, ...)
			local name = assert_select_type(2, {"string", "nil"}, nil, ...)
			local chunk = {}
			local i = 0
			while true do
				local piece = func()
				if piece == nil then
					break
				end
				local piece_type = type(piece)
				if piece_type ~= "string" and piece_type ~= "number" then
					error("reader function must return a string", 2)
				end
				i = i+1
				chunk[i] = piece
			end
			chunk = table.concat(chunk)
			if string.byte(chunk, 1, 1) == 0x1b then
				error("not implemented", 2)
			end
			return load(func, name, "t", env)
		end
		function env.loadstring(...)
			local str = assert_select_type(1, "string", nil, ...)
			local name = assert_select_type(2, {"string", "nil"}, nil, ...)
			if string.byte(str, 1, 1) == 0x1b then
				error("not implemented", 2)
			end
			if name == nil then
				name = str
			end
			return load(str, name, "t", env)
		end
		function env.math.atan2(...)
			local x = assert_select_type(1, "number", nil, ...)
			return math.atan(x)
		end
		function env.math.atan2(...)
			local y = assert_select_type(2, "number", nil, ...)
			local x = assert_select_type(1, "number", nil, ...)
			return math.atan(x, y)
		end
		function env.math.cosh(...)
			local x = assert_select_type(1, "number", nil, ...)
			return Math:cosh(x)
		end
		-- TODO: math.frexp
		function env.math.ldexp(...)
			local e = assert_select_type(2, "number", nil, ...)
			local m = assert_select_type(1, "number", nil, ...)
			return m*(2.^math.floor(e))
		end
		function env.math.log(...)
			local x = assert_select_type(1, "number", nil, ...)
			return math.log(x)
		end
		function env.math.log10(...)
			local x = assert_select_type(1, "number", nil, ...)
			return math.log(x, 10)
		end
		env.math.maxinteger = nil
		env.math.mininteger = nil
		env.math.mod = math.fmod
		function env.math.pow(...)
			local y = assert_select_type(2, "number", nil, ...)
			local x = assert_select_type(1, "number", nil, ...)
			return x^y
		end
		function env.math.sinh(...)
			local x = assert_select_type(1, "number", nil, ...)
			return Math:sinh(x)
		end
		function env.math.tanh(...)
			local x = assert_select_type(1, "number", nil, ...)
			return Math:tanh(x)
		end
		env.math.tointeger = nil
		env.math.type = nil
		env.math.ult = nil
		env.rawlen = nil
		function env.string.dump(...)
			local func = assert_select_type(1, "function", nil, ...)
			local info = debug.getinfo(func, "Su")
			if info.what ~= "Lua" then
				error("unable to dump given function", 2)
			end
			for i=1, info.nups do
				local name, value = debug.getupvalue(func, i)
				if name == "_ENV" then
					if value == _ENV then
						error("unable to dump given function", 2)
					end
					break
				end
			end
			return string.dump(func)
		end
		env.string.gfind = string.gmatch
		env.string.pack = nil
		env.string.packsize = nil
		env.string.unpack = nil
		function env.table.foreach(...)
			local tbl = assert_select_type(1, "table", nil, ...)
			local func = assert_select_type(2, "function", nil, ...)
			for k, v in pairs(tbl) do
				local retval = func(k, v)
				if retval ~= nil then
					return retval
				end
			end
		end
		function env.table.foreachi(...)
			local tbl = assert_select_type(1, "table", nil, ...)
			local func = assert_select_type(2, "function", nil, ...)
			local j = #tbl
			for i=1, j do
				local retval = func(i, tbl[i])
				if retval ~= nil then
					return retval
				end
			end
		end
		function env.table.getn(...)
			local tbl = assert_select_type(1, "table", nil, ...)
			return #tbl
		end
		function env.table.maxn(...)
			local tbl = assert_select_type(1, "table", nil, ...)
			local i = 0
			for k in pairs(tbl) do
				if k ~= k then
					error("table index is NaN", 2)
				end
				if type(k) == "number" and k > i then
					i = k
				end
			end
			return i
		end
		env.table.move = nil
		env.table.pack = nil
		function env.table.setn(...)
			local tbl = assert_select_type(1, "table", nil, ...)
			error("'setn' is obsolete", 2)
		end
		env.table.unpack = nil
		env.unpack = table.unpack
		env.utf8 = nil
		function env.getfenv(...)
			local location = assert_select_type(1, {"number", "function", "nil", "no value"}, nil, ...)
			if location == 0 then
				return env
			end
			if
				location == nil
				or location == math.huge
				or location == -math.huge
				or location ~= location
			then
				location = 1
			end
			local upvalue_count
			if type(location) == "number" then
				assert_condition(location >= 0, 1, "level must be non-negative")
				location = math.floor(location)+1
				local info = debug.getinfo(location, "uf")
				assert_condition(info ~= nil, 1, "invalid level")
				location = info.func
				upvalue_count = info.nups
			else
				upvalue_count = debug.getinfo(location, "u").nups
			end
			for i=1, upvalue_count do
				local name, value = debug.getupvalue(location, i)
				if name == "_ENV" then
					if value == _ENV then
						value = env
					end
					return value
				end
			end
			return env
		end
		function env.setfenv(...)
			local fenv = assert_select_type(2, "table", nil, ...)
			local location = assert_select_type(1, {"number", "function"}, nil, ...)
			if
				location == nil
				or location == math.huge
				or location == -math.huge
				or location ~= location
			then
				location = 1
			end
			local upvalue_count
			if type(location) == "number" then
				assert_condition(location >= 0, 1, "level must be non-negative")
				location = math.floor(location)
				assert_condition(location ~= 0, 1, "not implemented") -- TODO
				location = location+1
				local info = debug.getinfo(location, "uf")
				assert_condition(info ~= nil, 1, "invalid level")
				location = info.func
				upvalue_count = info.nups
			else
				upvalue_count = debug.getinfo(location, "u").nups
			end
			for i=1, upvalue_count do
				local name, value = debug.getupvalue(location, i)
				if name == "_ENV" then
					if value == _ENV then
						error("'setfenv' cannot change environment of given object", 2)
					end
					debug.setupvalue(location, i, fenv)
					return location
				end
			end
			return location
		end
	else
		if not pcall(collectgarbage, "count") then
			env.collectgarbage = nil
		end
		function env.load(...)
			local chunk = assert_select_type(1, {"function", "string"}, nil, ...)
			local name = assert_select_type(2, {"string", "no value", "nil"}, nil, ...)
			local mode = assert_select_type(3, {"string", "no value", "nil"}, nil, ...)
			local fenv = assert_select_type(4, {"table", "no value", "nil"}, nil, ...)
			if type(chunk) == "function" then
				local func = chunk
				chunk = {}
				local i = 0
				while true do
					local piece = func()
					if piece == nil then
						break
					end
					local piece_type = type(piece)
					if piece_type ~= "string" and piece_type ~= "number" then
						error("reader function must return a string", 2)
					end
					i = i+1
					chunk[i] = piece
				end
				chunk = table.concat(chunk)
			end
			if mode == nil then
				mode = "bt"
			else
				local null = string.find(mode, "\x00", 1, true)
				if null ~= nil then
					mode = string.sub(mode, 1, null-1)
				end
			end
			if string.byte(chunk, 1, 1) == 0x1b then
				if not string.find(mode, "b", 1, true) then
					error(string.format("attempt to load a binary chunk (mode is '%s')", mode), 2)
				end
				error("not implemented", 2)
			elseif not string.find(mode, "t", 1, true) then
				error(string.format("attempt to load a text chunk (mode is '%s')", mode), 2)
			end
			mode = "t"
			if fenv == nil then
				fenv = env
			end
			return load(chunk, name, mode, fenv)
		end
		function env.string.dump(...)
			local func = assert_select_type(1, "function", nil, ...)
			local strip = not not select(2, ...)
			local info = debug.getinfo(func, "Su")
			if info.what ~= "Lua" then
				error("unable to dump given function", 2)
			end
			for i=1, info.nups do
				local name, value = debug.getupvalue(func, i)
				if name == "_ENV" then
					if value == _ENV then
						error("unable to dump given function", 2)
					end
					break
				end
			end
			return string.dump(func, strip)
		end
	end
	env._FASTPOUR = true
	local libraries = self.libraries
	for i=1, #libraries do
		libraries[i](self, env)
	end
	return env
end

function script:callback_init()
	local env = self.env
	local callbacks = self.callbacks
	-- this will invoke metamethods!!
	callbacks.init = env.init ~= nil
	callbacks.update = env.update ~= nil
	callbacks.tick = env.tick ~= nil
	callbacks.draw = env.draw ~= nil
	callbacks.handleCommand = env.handleCommand ~= nil
end
local function vararg_capture(...)
	return {...}, select("#", ...)
end
script._vararg_capture = vararg_capture
function script:callback_call(k, ...)
	if not self.callbacks[k] then
		return
	end
	return self:pcall(self.env[k], ...)
end

function script:pcall(func, ...)
	local retvals, j = vararg_capture(pcall(func, ...))
	if not retvals[1] then
		local err = retvals[2]
		local client = self.client
		if client ~= nil then
			client:debug_print(err)
		end
		local err_type = type(err)
		if err_type == "number" then
			err = tostring(err)
		elseif err_type ~= "string" then
			err = "(error object is not a string)"
		end
		console:error("Runtime error: %s", err)
	end
	return table.unpack(retvals, 1, j)
end
function script:loadfile(path, ...)
	local client = self.client
	local data, err = client.filesystem:read(path)
	if data == nil then
		return nil, err
	end
	data, err = load(data, path, "t", self.env)
	if data == nil then
		client:debug_print(err)
		console:error("Compilation error: %s", err)
		return nil, err
	end
	return data
end
function script:dofile(path, ...)
	local func, err = self:loadfile(path, ...)
	if func == nil then
		return false, err
	end
	return self:pcall(func, ...)
end

return script
