local filesystem = dofile("./filesystem.lua")
local script = dofile("./script.lua")

local client = {}
client.__index = client
function client.new()
	return setmetatable({
		state = client.STATE_INVALID,
		game_path = "Y:/Teardown/",
		mod_path = "mods/fastpour/",
		debug_log = {},
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
	local my_filesystem = filesystem.new()
	self.filesystem = my_filesystem
	local game_path = self.game_path
	assert(my_filesystem:mkdir(game_path, true))
	assert(my_filesystem:cd(game_path))
	local mod_path = self.mod_path
	assert(my_filesystem:mkdir(mod_path, true))
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
	my_script:env_init()
	my_script:dofile(path)
	my_script:callback_init()
	--if my_script.callbacks.draw then
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
	script:callback_call("tick", dt)
	script:callback_call("draw", dt)
	self.last = now
	ctx.font = "16px monospace"
	ctx.fillStyle = "white"
	local debug_log = self.debug_log
	for i=1, self.DEBUG_LOG_MAX do
		ctx:fillText(debug_log[i], 50, 670+(i-1)*18)
	end
end

return client
