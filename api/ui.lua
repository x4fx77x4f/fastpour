return function(self, env)
	local ctx = self.ctx
	local weak_assert_select_type = self._weak_assert_select_type
	local to_sane = self._to_sane
	local weak_assert_argument = self._weak_assert_argument
	-- UiMakeInteractive
	-- UiPush
	-- UiPop
	-- UiWidth
	-- UiHeight
	-- UiCenter
	-- UiMiddle
	function env.UiColor(...)
		-- TODO: edge cases
		local r = weak_assert_select_type(self, 1, "number", nil, ...)
		weak_assert_argument(self, r >= 0 and r <= 1, 1, "out of range")
		local g = weak_assert_select_type(self, 2, "number", nil, ...)
		weak_assert_argument(self, g >= 0 and g <= 1, 2, "out of range")
		local b = weak_assert_select_type(self, 3, "number", nil, ...)
		weak_assert_argument(self, b >= 0 and b <= 1, 3, "out of range")
		local a = weak_assert_select_type(self, 4, {"number", "no value", "nil"}, nil, ...)
		if a == nil then
			a = 1
		else
			weak_assert_argument(self, a >= 0 and a <= 1, 4, "out of range")
		end
		ctx.fillStyle = string.format("rgb(%s %s %s / %s)", r*255, g*255, b*255, a)
	end
	-- UiColorFilter
	function env.UiTranslate(...)
		-- TODO: edge cases
		local x = weak_assert_select_type(self, 1, "number", nil, ...)
		weak_assert_argument(self, to_sane(x), 1, "out of range")
		local y = weak_assert_select_type(self, 2, "number", nil, ...)
		weak_assert_argument(self, to_sane(y), 2, "out of range")
		ctx:translate(x, y)
	end
	-- UiRotate
	function env.UiScale(...)
		-- TODO: edge cases
		local w = weak_assert_select_type(self, 1, "number", nil, ...)
		weak_assert_argument(self, to_sane(w), 1, "out of range")
		local h = weak_assert_select_type(self, 2, "number", nil, ...)
		weak_assert_argument(self, to_sane(h), 2, "out of range")
		ctx:scale(w, h)
	end
	-- UiWindow
	-- UiSafeMargins
	function env.UiAlign(...)
		local alignment = weak_assert_select_type(self, 1, "string", nil, ...)
		-- TODO: unstub
	end
	-- UiModalBegin
	-- UiModalEnd
	-- UiDisableInput
	-- UiEnableInput
	-- UiReceivesInput
	-- UiGetMousePos
	-- UiIsMouseInRect
	-- UiWorldToPixel
	-- UiPixelToWorld
	-- UiBlur
	local client = self.client
	local my_filesystem = client.filesystem
	local game_path = client.game_path
	my_filesystem:write(game_path.."/data/ui/font/regular.ttf", "normal %dpx Lato, sans-serif")
	my_filesystem:write(game_path.."/data/ui/font/bold.ttf", "bold %dpx Lato, sans-serif")
	my_filesystem:write(game_path.."/data/ui/font/RobotoMono-Regular.ttf", "normal %dpx \"Roboto Mono\", monospace, monospace")
	function env.UiFont(...)
		-- TODO: edge cases
		local path = weak_assert_select_type(self, 1, "string", nil, ...)
		local font, err = my_filesystem:read(game_path.."/data/ui/font/"..path)
		if font == nil then
			weak_assert_argument(self, false, 1, err)
			return
		end
		local size = weak_assert_select_type(self, 2, "number", nil, ...)
		if size < 10 or size > 100 then
			weak_assert_argument(self, false, 2, "out of range")
			return
		end
		font = string.format(font, size)
		self.font = font
		self.font_size = size
		ctx.font = font
	end
	function env.UiFontHeight(...)
		-- TODO: edge cases; i don't think this is exactly right
		local size = self.font_size
		if size == nil then
			if self.strict then
				error("no font set", 2)
			end
			return
		end
		return size
	end
	function env.UiText(...)
		-- TODO: edge cases, align
		local text = weak_assert_select_type(self, 1, "string", nil, ...)
		if text == nil then
			text = ""
		end
		local move = weak_assert_select_type(self, 2, {"boolean", "no value", "nil"}, nil, ...)
		local w, h = 0, 0
		local size = self.font_size
		local i = 1
		local lines = 0
		while true do
			local j = string.find(text, "\n", i, true)
			local line
			if j ~= nil then
				line = string.sub(text, i, j-1)
			else
				line = string.sub(text, i)
			end
			ctx:fillText(line, 0, 0)
			line = lines+1
			ctx:translate(0, size)
			local metrics = ctx:measureText(text)
			w, h = math.max(w, metrics.width), h+size
			if j == nil then
				break
			end
			i = j+1
		end
		if not move then
			ctx:translate(0, -h)
		end
		return w, h
	end
	-- UiGetTextSize
	-- UiWordWrap
	-- UiTextOutline
	-- UiTextShadow
	function env.UiRect(...)
		-- TODO: edge cases, align
		local w = weak_assert_select_type(self, 1, "number", nil, ...)
		weak_assert_argument(self, to_sane(w), 1, "out of range")
		local h = weak_assert_select_type(self, 2, "number", nil, ...)
		weak_assert_argument(self, to_sane(h), 2, "out of range")
		ctx:fillRect(0, 0, w, h)
	end
	-- UiImage
	-- UiGetImageSize
	-- UiImageBox
	-- UiSound
	-- UiSoundLoop
	-- UiMute
	-- UiButtonImageBox
	-- UiButtonHoverColor
	-- UiButtonPressColor
	-- UiButtonPressDist
	-- UiTextButton
	-- UiImageButton
	-- UiBlankButton
	-- UiSlider
	-- UiGetScreen
end
