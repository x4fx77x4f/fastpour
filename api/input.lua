return function(self, env)
	local weak_assert_select_type = self._weak_assert_select_type
	local code_to_physical = {
		Escape = "esc",
		F1 = "f1",
		F2 = "f2",
		F3 = "f3",
		F4 = "f4",
		F5 = "f5",
		F6 = "f6",
		F7 = "f7",
		F8 = "f8",
		F9 = "f9",
		F10 = "f10",
		F11 = "f11",
		F12 = "f12",
		Backquote = nil,
		Digit1 = "1",
		Digit2 = "2",
		Digit3 = "3",
		Digit4 = "4",
		Digit5 = "5",
		Digit6 = "6",
		Digit7 = "7",
		Digit8 = "8",
		Digit9 = "9",
		Digit0 = "0",
		Minus = nil,
		Equal = nil,
		Backspace = "backspace",
		Tab = "tab",
		BracketLeft = nil,
		BracketRight = nil,
		Backslash = nil,
		CapsLock = nil,
		Semicolon = nil,
		Quote = nil,
		ShiftLeft = "shift",
		Comma = nil,
		Period = nil,
		Slash = nil,
		ShiftRight = "shift",
		ControlLeft = "ctrl",
		OSLeft = nil,
		AltLeft = "alt",
		Space = "space",
		AltRight = "alt",
		OSRight = nil,
		ContextMenu = nil,
		ControlRight = "ctrl",
		PrintScreen = nil,
		ScrollLock = nil,
		Pause = nil,
		Insert = "insert",
		Home = "home",
		PageUp = "pgup",
		Delete = "delete",
		End = "end",
		PageDown = "pgdown",
		ArrowUp = "uparrow",
		ArrowLeft = "leftarrow",
		ArrowDown = "downarrow",
		ArrowRight = "rightarrow",
		NumLock = nil,
		NumpadDivide = "O",
		NumpadMultiply = "J",
		NumpadSubtract = "M",
		Numpad7 = "G",
		Numpad8 = "H",
		Numpad9 = "I",
		NumpadAdd = "K",
		Numpad4 = "D",
		Numpad5 = "E",
		Numpad6 = "F",
		Numpad1 = "A",
		Numpad2 = "B",
		Numpad3 = "C",
		NumpadEnter = "return",
		Numpad0 = nil,
		NumpadDecimal = "N",
	}
	self.code_to_physical = code_to_physical
	for i=0, 9 do
		local digit = ""..i
		code_to_physical["Digit"..digit] = digit
	end
	for codepoint=0x41, 0x5a do
		local character = string.char(codepoint)
		code_to_physical["Key"..character] = character
	end
	code_to_physical.MetaLeft = code_to_physical.OSLeft
	code_to_physical.MetaRight = code_to_physical.OSRight
	local viewport = self.client.viewport
	local input_state = {}
	self.input_state = input_state
	viewport:addEventListener("keydown", function(_, event)
		if event["repeat"] or event.metaKey then
			return
		end
		local physical = code_to_physical[event.code]
		if physical == nil then
			return
		end
		event:preventDefault()
		local state = input_state[physical]
		if state == nil then
			input_state[physical] = "pressed"
			self.input_last_pressed = physical
		elseif state == "pressed" then
			input_state[physical] = "held"
		end
	end)
	viewport:addEventListener("keyup", function(_, event)
		local physical = code_to_physical[event.code]
		if physical == nil then
			return
		end
		event:preventDefault()
		input_state[physical] = "released"
	end)
	local button_to_input = {
		[0] = "lmb",
		[1] = "mmb",
		[2] = "rmb",
		[3] = nil,
		[4] = nil,
	}
	self.button_to_input = button_to_input
	-- TODO: mousedown/moseup
	local logical_to_physical = {
		up = "w",
		down = "s",
		left = "a",
		right = "d",
		interact = "e",
		flashlight = "f",
		jump = "space",
		crouch = "ctrl",
		usetool = "lmb",
		grab = "rmb",
		handbrake = "space",
		map = "tab",
		pause = "esc",
		vehicleraise = "rmb",
		vehiclelower = "lmb",
		vehicleaction = "space",
	}
	self.logical_to_physical = logical_to_physical
	function env.InputLastPressedKey(...)
		return self.input_last_pressed
	end
	function env.InputPressed(...)
		local input = weak_assert_select_type(self, 1, "string", nil, ...)
		input = string.lower(input)
		local physical = logical_to_physical[input]
		if physical ~= nil then
			input = physical
		end
		return input_state[input] == "pressed"
	end
	function env.InputReleased(...)
		local input = weak_assert_select_type(self, 1, "string", nil, ...)
		input = string.lower(input)
		local physical = logical_to_physical[input]
		if physical ~= nil then
			input = physical
		end
		return input_state[input] == "released"
	end
	function env.InputDown(...)
		local input = weak_assert_select_type(self, 1, "string", nil, ...)
		input = string.lower(input)
		local physical = logical_to_physical[input]
		if physical ~= nil then
			input = physical
		end
		local state = input_state[input]
		return state == "held" or state == "pressed"
	end
	function env.InputValue(...)
		local input = weak_assert_select_type(self, 1, "string", nil, ...)
		input = string.lower(input)
		local physical = logical_to_physical[input]
		if physical ~= nil then
			input = physical
		end
		local state = input_state[input]
		if state == "held" or state == "pressed" then
			return 1
		end
		return 0
	end
end
