return function(self, env)
	local weak_assert_select_type = self._weak_assert_select_type
	-- Shoot
	-- Paint
	-- MakeHole
	-- Explosion
	-- SpawnFire
	-- GetFireCount
	-- QueryClosestFire
	-- QueryAabbFireCount
	-- RemoveAabbFires
	-- GetCameraTransform
	-- SetCameraTransform
	-- SetCameraFov
	-- SetCameraDof
	-- PointLight
	-- SetTimeScale (does this do anything if not in PLAY)
	-- SetEnvironmentDefault
	-- SetEnvironmentProperty
	-- GetEnvironmentProperty
	-- SetPostProcessingDefault
	-- SetPostProcessingProperty
	-- GetPostProcessingProperty
	-- DrawLine
	-- DebugLine
	-- DebugCross
	function env.DebugWatch(...)
		local key = weak_assert_select_type(self, 1, "string", nil, ...)
		local value = select(2, ...)
		-- TODO: unstub
	end
	function env.DebugPrint(...)
		local str = weak_assert_select_type(self, 1, "string", nil, ...)
		self.client:debug_print(str)
	end
end
