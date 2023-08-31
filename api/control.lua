local fastpour = fastpour
local cachebuster = fastpour.cachebuster
local builds = dofile("./builds.lua"..cachebuster)
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
	-- input stuff is in input.lua
	-- SetValue
	-- PauseMenuButton
	-- StartLevel
	-- SetPaused
	-- Restart
	-- Menu
end
