return function(self, env)
	function env.DebugPrint(str)
		local client = self.client
		if client == nil then
			return
		end
		client:debug_print(str)
	end
end
