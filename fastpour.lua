local js = require("js")
local window = js.global
local document = window.document
local console = window.console

local function copy(src, seen)
	local dst = {}
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
local function split(str, separator)
	local tbl, tbl_i, str_i = {}, 0, 1
	while true do
		local str_j = string.find(str, separator, str_i)
		tbl_i = tbl_i+1
		if str_j == nil then
			tbl[tbl_i] = string.sub(str, str_i)
			break
		end
		tbl[tbl_i] = string.sub(str, str_i, str_j-1)
		str_i = str_j+1
	end
	return tbl
end

local reserved_names = {
	con = true,
	prn = true,
	aux = true,
	nul = true,
}
for i=0, 9 do
	reserved_names["com"..i] = true
	reserved_names["lpt"..i] = true
end
setmetatable(reserved_names, {
	__index = function(self, k)
		local i = string.find(k, ".", 1, true)
		if i ~= nil then
			k = string.sub(k, 1, i-1)
		end
		k = string.lower(k)
		return rawget(self, k)
	end,
})
local function path_info(path)
	path = string.gsub(path, "\\", "/")
	path = string.lower(path)
	local absolute = string.match(path, "^(%l:)/") or string.find(path, 1, 1) == "/"
	local directory = string.sub(path, -1, -1) == "/"
	local traversal = false
	local valid = string.find(path, "[<>:\"|?*\0-\31]", type(absolute) == "string" and 4 or 1) == nil and string.sub(path, 1, 2) ~= "//"
	path = split(path, "/")
	local i = 1
	while true do
		local path_segment = path[i]
		if path_segment == nil then
			break
		elseif path_segment == "" or path_segment == "." then
			table.remove(path, i)
		elseif path_segment == ".." then
			table.remove(path, i)
			if i > 1 then
				i = i-1
				table.remove(path, i)
			else
				traversal = true
			end
		else
			if reserved_names[path_segment] or string.find(path_segment, "[. ]$") ~= nil then
				valid = false
			end
			i = i+1
		end
	end
	return path, valid, absolute, traversal, directory
end
local filesystem
local filesystem_cwd
local function filesystem_resolve(path)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = path_info(path)
	if absolute == true then
		table.insert(path, 1, filesystem_cwd[1])
	elseif not absolute then
		for i=1, #filesystem_cwd do
			table.insert(path, i, filesystem_cwd[i])
		end
	end
	return path, valid, absolute, traversal, directory
end
local function filesystem_read(path)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = filesystem_resolve(path)
	if not valid then
		return nil, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = filesystem
	for i=1, #path-1 do
		node = node[path[i]]
		if type(node) ~= "table" then
			return nil, "not a directory", path, valid, absolute, traversal, directory
		end
	end
	node = node[path[#path]]
	return node, "no such file", path, valid, absolute, traversal, directory
end
local function filesystem_write(path, data)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = filesystem_resolve(path)
	if not valid then
		return false, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = filesystem
	for i=1, #path-1 do
		node = node[path[i]]
		if type(node) ~= "table" then
			return false, "not a directory", path, valid, absolute, traversal, directory
		end
	end
	node[path[#path]] = data
	return true
end
local function filesystem_mkdir(path, make_ascendants)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = filesystem_resolve(path)
	if not valid then
		return false, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = filesystem
	for i=1, #path do
		local path_segment = path[i]
		local next_node = node[path_segment]
		if next_node == nil and (make_ascendants or i == #path) then
			next_node = {}
			node[path_segment] = next_node
		elseif type(next_node) ~= "table" then
			return false, "not a directory", path, valid, absolute, traversal, directory
		end
		node = next_node
	end
	return true
end

local viewport = document:getElementById("fp-viewport")
local textarea = document:getElementById("fp-textarea")
local button_start = document:getElementById("fp-start")
local button_stop = document:getElementById("fp-stop")
local checkbox_lua51 = document:getElementById("fp-lua51")

local function create_env(path)
	local env = copy(_ENV)
	env._COPYRIGHT = nil
	env.debug = nil
	env.dofile = nil
	env.load = nil
	env.loadfile = nil
	env.os = nil
	env.require = nil
	env.fengari = nil
	env.js = nil
	if checkbox_lua51.checked then
		env._VERSION = "Lua 5.1"
		function env.load(func, name)
			assert(type(func) == "function", "bad argument #1 to load (expected function)")
			return load(func, name, "t", env)
		end
		function env.loadstring(str, name)
			assert(type(str) == "string", "bad argument #1 to loadstring (expected string)")
			if name == nil then
				name = str
			end
			return load(str, name, "t", env)
		end
		function env.math.log(x)
			return math.log(x)
		end
		function env.math.log10(x)
			return math.log(x, 10)
		end
		function env.table.maxn(tbl)
			local i = 0
			for k in pairs(tbl) do
				if type(k) == "number" and k > i and k < math.huge then
					i = k
				end
			end
			return i
		end
		env.unpack = table.unpack
	end
end
local env, has_init, has_update, has_tick, has_draw, has_handleCommand
local function startui(path)
	env = create_env(path)
	local err
	code, err = filesystem_read(path)
	if code == nil then
		console:error("failed to read file '%s' (%s); treating as empty", path, err)
		code = ""
	end
	code, err = load(code, path)
	if code == nil then
		console:error("failed to compile: %s", tostring(err))
		code = function() end
	end
	local success, err = pcall(code)
	if not success then
		console:error("script error: %s", tostring(err))
	end
	has_init = env.init ~= nil
	has_update = env.update ~= nil
	has_tick = env.tick ~= nil
	has_draw = env.draw ~= nil
	has_handleCommand = env.handleCommand ~= nil
end

button_start:addEventListener("click", function(self, event)
	filesystem = {}
	assert(filesystem_mkdir("Y:/Teardown/data/ui", true))
	filesystem_cwd = filesystem_resolve("Y:/Teardown/")
	local path = "data/ui/fastpour.lua"
	assert(filesystem_write(path, textarea.value))
	startui(path)
end)