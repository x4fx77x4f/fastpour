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
	-- UiAlign
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
	-- UiFont
	-- UiFontHeight
	-- UiText
	-- UiGetTextSize
	-- UiWordWrap
	-- UiTextOutline
	-- UiTextShadow
	function env.UiRect(...)
		-- TODO: edge cases
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
