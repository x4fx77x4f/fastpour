local js = require("js")
local window = js.global
local document = window.document
local console = window.console

local function ypcall(func, ...)
	local args, j = {...}, select("#", ...)
	return xpcall(function()
		return func(table.unpack(args, 1, j)) -- this is so awful
	end, function(err)
		err = debug.traceback(err, 2)
		console:error(err)
	end)
end
local function ypcall_wrap(func)
	return function(...)
		return ypcall(func, ...)
	end
end
ypcall(function(...)

local client = dofile("./client.lua")

local viewport = document:getElementById("fp-viewport")
local ctx = assert(viewport:getContext("2d"))
local textarea = document:getElementById("fp-textarea")
local button_start = document:getElementById("fp-start")
local button_stop = document:getElementById("fp-stop")
local checkbox_lua51 = document:getElementById("fp-lua51")

local animation_id, saved, my_client
local function draw(self, now)
	if saved then
		ctx:restore()
		saved = false
	end
	ctx:save()
	saved = true
	--ctx:reset()
	my_client:tick(now/1000)
	if animation_id ~= nil then
		animation_id = window:requestAnimationFrame(draw)
	end
end
draw = ypcall_wrap(draw)
button_start:addEventListener("click", ypcall_wrap(function(self, event)
	if animation_id ~= nil then
		window:cancelAnimationFrame(animation_id)
		animation_id = nil
	end
	my_client = client.new()
	my_client:init()
	local path = my_client.mod_path.."/options.lua"
	my_client.filesystem:write(path, textarea.value)
	my_client:start_ui(path)
	client.ctx = ctx
	client.width = viewport.width
	client.height = viewport.height
	animation_id = window:requestAnimationFrame(draw)
end))
button_stop:addEventListener("click", ypcall_wrap(function(self, event)
	if animation_id == nil then
		return
	end
	window:cancelAnimationFrame(animation_id)
	animation_id = nil
end))

end, ...)
