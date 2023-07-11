local builds = dofile("./builds.lua")
return function(self, env)
	function env.GetVersion()
		-- TODO: does writing to game.version affect this?
		return builds[self.client.buildid][1]
	end
	-- HasVersion
	function env.GetTime()
		-- there may be subtle unavoidable differences in behavior with all time-related things
		-- TODO: what should happen if this is called before init?
		return self.client.now
	end
	function env.GetTimeStep()
		-- TODO: what should happen if this is called before init?
		return self.client.dt
	end
	-- InputLastPressedKey
	-- InputPressed
	-- InputReleased
	-- InputDown
	-- InputValue
	-- SetValue
	-- PauseMenuButton
	-- StartLevel
	-- SetPaused
	-- Restart
	-- Menu
end
