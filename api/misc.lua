return function(self, env)
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
	-- DebugWatch
	function env.DebugPrint(str)
		self.client:debug_print(str)
	end
end
