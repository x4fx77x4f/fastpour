local js = require("js")
local window = js.global
local document = window.document
local console = window.console

local filesystem = dofile("./filesystem.lua")
local my_filesystem = filesystem.new()

local viewport = document:getElementById("fp-viewport")
local ctx = assert(viewport:getContext("2d"))
local textarea = document:getElementById("fp-textarea")
local button_start = document:getElementById("fp-start")
local button_stop = document:getElementById("fp-stop")
local checkbox_lua51 = document:getElementById("fp-lua51")

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
local DEBUG_LOG_MAX = 20
local env, has, debug_log
local function debugprint(str)
	for i=1, DEBUG_LOG_MAX-1 do
		debug_log[i] = debug_log[i+1]
	end
	debug_log[DEBUG_LOG_MAX] = str
end
local function create_env()
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
	function env.DebugPrint(str)
		if type(str) ~= "string" then return end
		return debugprint(str)
	end
	return env
end
local function env_pcall(k, ...)
	if not has[k] then
		return
	end
	local func = env[k]
	local success, err = pcall(func, ...)
	if not success then
		err = tostring(err)
		console:error("script error: %s", err)
		debugprint(err)
	end
end
local function startui(path)
	debug_log = {}
	for i=1, DEBUG_LOG_MAX do
		debug_log[i] = ""
	end
	env = create_env()
	local err
	code, err = my_filesystem:read(path)
	if code == nil then
		console:error("failed to read file '%s' (%s); treating as empty", path, err)
		code = ""
	end
	code, err = load(code, path, "t", env)
	if code == nil then
		console:error("failed to compile: %s", tostring(err))
		code = function() end
	end
	local success, err = pcall(code)
	if not success then
		console:error("script error: %s", tostring(err))
	end
	-- yes, i know this will trigger metamethods
	has = {}
	has.init = env.init ~= nil
	has.update = env.update ~= nil
	has.tick = env.tick ~= nil
	has.draw = env.draw ~= nil
	has.handleCommand = env.handleCommand ~= nil
	env_pcall("init")
end

local animation_id, draw, saved, last
function draw(self, now)
	if saved then
		ctx:restore()
		saved = false
	end
	ctx:save()
	saved = true
	--ctx:reset()
	local w, h = viewport.width, viewport.height
	ctx.fillStyle = "black"
	ctx:fillRect(0, 0, w, h)
	local scale = math.min(w/1920, h/1080)
	ctx:scale(scale, scale)
	now = now/1000
	if last == nil then
		last = now
	end
	local dt = now-last
	env_pcall("tick", dt)
	env_pcall("draw", dt)
	last = now
	ctx.font = "16px monospace"
	ctx.fillStyle = "white"
	for i=1, DEBUG_LOG_MAX do
		ctx:fillText(debug_log[i], 50, 670+(i-1)*18)
	end
	if animation_id ~= nil then
		animation_id = window:requestAnimationFrame(draw)
	end
end
button_start:addEventListener("click", function(self, event)
	if animation_id ~= nil then
		window:cancelAnimationFrame(animation_id)
		animation_id = nil
	end
	assert(my_filesystem:mkdir("Y:/Teardown/data/ui", true))
	my_filesystem.cwd = my_filesystem:resolve("Y:/Teardown/")
	local path = "data/ui/fastpour.lua"
	assert(my_filesystem:write(path, textarea.value))
	startui(path)
	animation_id = window:requestAnimationFrame(draw)
end)
button_stop:addEventListener("click", function(self, event)
	if animation_id == nil then
		return
	end
	window:cancelAnimationFrame(animation_id)
	animation_id = nil
end)
