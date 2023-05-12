"use strict";
window.addEventListener("load", event => {
	const viewport = document.getElementById("fp-viewport");
	const textarea = document.getElementById("fp-textarea");
	const start = document.getElementById("fp-start");
	const stop = document.getElementById("fp-stop");
	
	const luaconf = fengari.luaconf;
	const lua = fengari.lua;
	const lauxlib = fengari.lauxlib;
	const lualib = fengari.lualib;
	let L = null;
	let running = false;
	let has_tick = false;
	let has_update = false;
	let has_draw = false;
	let has_handleCommand = false;
	function init() {
		console.log("Initializing guest");
		running = false;
		L = lauxlib.luaL_newstate();
		lualib.luaopen_base(L);
		lualib.luaopen_coroutine(L);
		lualib.luaopen_string(L);
		lualib.luaopen_table(L);
		lualib.luaopen_math(L);
		let read = false;
		const retval = lua.lua_load(L, (L, data, size) => {
			if (read) return null;
			read = true;
			return textarea.value;
		}, null, "C:/users/steamuser/Documents/Teardown/mods/fastpour/options.lua", "t");
		if (retval != lua.LUA_OK) {
			const err = lua.lua_tolstring(L, -1);
			lua.lua_pop(L, 1);
			let err2;
			switch (retval) {
				case lua.LUA_ERRSYNTAX:
					err2 = "LUA_ERRSYNTAX";
					break;
				case lua.LUA_ERRMEM:
					err2 = "LUA_ERRMEM";
					break;
				case lua.LUA_ERRGCMM:
					err2 = "LUA_ERRGCMM";
					break;
				default:
					err2 = "?";
			}
			console.error(`Failed to compile guest (${retval}: ${err2}): ${err}`);
			return;
		}
		console.log("Compiled guest");
	}
	function draw() {
		
	}
	
	start.addEventListener("click", event => {
		init();
	});
	stop.addEventListener("click", event => running = false);
});