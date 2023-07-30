local fastpour = fastpour
local cachebuster = fastpour.cachebuster
local filesystem = dofile("./filesystem.lua"..cachebuster)
local script = dofile("./script.lua"..cachebuster)

local client = {}
client.__index = client
function client.new()
	return setmetatable({
		state = client.STATE_INVALID,
		game_path = "Y:/Teardown/",
		mod_path = "mods/fastpour/",
		debug_log = {},
		buildid = 11527952,
		env_spoof_lua51 = true,
	}, client)
end

client.STATE_SPLASH = 1
client.STATE_MENU = 2
client.STATE_UI = 3
client.STATE_PLAY = 4
client.STATE_EDIT = 5
client.STATE_QUIT = 6
client.STATE_INVALID = 7
client.DEBUG_LOG_MAX = 20

function client:init()
	assert(self.buildid == 11527952)
	local my_filesystem = filesystem.new()
	self.filesystem = my_filesystem
	local game_path = self.game_path
	assert(my_filesystem:mkdir(game_path, true))
	assert(my_filesystem:cd(game_path))
	local mod_path = self.mod_path
	assert(my_filesystem:mkdir(mod_path, true))
	assert(my_filesystem:mkdir("data/ui/font/", true))
end
function client:debug_clear()
	local debug_log = self.debug_log
	for i=1, self.DEBUG_LOG_MAX do
		debug_log[i] = ""
	end
end
function client:debug_print(str)
	local str_type = type(str)
	if str_type ~= "string" then
		if str_type == "number" then
			str = tostring(str)
		else
			str = ""
		end
	end
	local debug_log = self.debug_log
	-- TODO: this sucks
	local DEBUG_LOG_MAX = self.DEBUG_LOG_MAX
	for i=1, DEBUG_LOG_MAX-1 do
		debug_log[i] = debug_log[i+1]
	end
	debug_log[DEBUG_LOG_MAX] = str
end
function client:start_ui(path)
	self.state = self.STATE_UI
	self:debug_clear()
	local my_script = script.new(self)
	self.script = my_script
	my_script.ctx = self.ctx
	my_script.env_spoof_lua51 = self.env_spoof_lua51
	my_script.strict = self.strict
	my_script:env_init()
	my_script:dofile(path)
	my_script:callback_init()
	if my_script.callbacks.draw then
		my_script.libraries.ui(my_script, my_script.env)
	end
	my_script:callback_call("init")
end
function client:tick(now)
	local ctx = self.ctx
	local w, h = self.width, self.height
	ctx.fillStyle = "black"
	ctx:fillRect(0, 0, w, h)
	local scale = math.min(w/1920, h/1080)
	ctx:scale(scale, scale)
	local last = self.last
	if last == nil then
		last = now
	end
	local dt = now-last
	local script = self.script
	self.now = now
	self.dt = dt
	ctx:save()
	script.font = nil
	script.font_size = nil
	ctx.fillStyle = "white"
	--script:callback_call("update", dt) -- TODO
	script:callback_call("tick", dt)
	script:callback_call("draw", dt)
	ctx:restore()
	self.last = now
	ctx.font = "normal 16px monospace, monospace"
	ctx.fillStyle = "white"
	local debug_log = self.debug_log
	for i=1, self.DEBUG_LOG_MAX do
		ctx:fillText(debug_log[i], 50, 670+(i-1)*18)
	end
end

return client
