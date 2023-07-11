local function split(str, separator)
	local tbl, tbl_i, str_i = {}, 0, 1
	while true do
		local str_j = string.find(str, separator, str_i)
		tbl_i = tbl_i+1
		if str_j == nil then
			tbl[tbl_i] = string.sub(str, str_i)
			break
		end
		tbl[tbl_i] = string.sub(str, str_i, str_j-1)
		str_i = str_j+1
	end
	return tbl
end

local filesystem = {}
filesystem.__index = filesystem
function filesystem.new()
	return setmetatable({
		root = {
			["c:"] = {},
		},
		cwd = {"c:"},
	}, filesystem)
end

local reserved_names = {
	con = true,
	prn = true,
	aux = true,
	nul = true,
}
for i=0, 9 do
	reserved_names[string.format("com%d", i)] = true
	reserved_names[string.format("lpt%d", i)] = true
end
setmetatable(reserved_names, {
	__index = function(self, k)
		if type(k) ~= "string" then
			return
		end
		local i = string.find(k, ".", 1, true)
		if i ~= nil then
			k = string.sub(k, 1, i-1)
		end
		k = string.lower(k)
		return rawget(self, k)
	end,
})
filesystem.reserved_names = reserved_names

local function path_info(path)
	path = string.gsub(path, "\\", "/")
	path = string.lower(path)
	local absolute = string.match(path, "^(%l:)/") or string.find(path, 1, 1) == "/"
	local directory = string.sub(path, -1, -1) == "/"
	local traversal = false
	local valid = string.find(path, "[<>:\"|?*\0-\31]", type(absolute) == "string" and 4 or 1) == nil and string.sub(path, 1, 2) ~= "//"
	path = split(path, "/")
	local i = 1
	while true do
		local path_segment = path[i]
		if path_segment == nil then
			break
		elseif path_segment == "" or path_segment == "." then
			table.remove(path, i)
		elseif path_segment == ".." then
			table.remove(path, i)
			if i > 1 then
				i = i-1
				table.remove(path, i)
			else
				traversal = true
			end
		else
			if reserved_names[path_segment] or string.find(path_segment, "[. ]$") ~= nil then
				valid = false
			end
			i = i+1
		end
	end
	return path, valid, absolute, traversal, directory
end
filesystem.path_info = path_info

function filesystem:resolve(path)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = path_info(path)
	local cwd = self.cwd
	if absolute == true then
		table.insert(path, 1, cwd[1])
	elseif not absolute then
		for i=1, #cwd do
			table.insert(path, i, cwd[i])
		end
	end
	return path, valid, absolute, traversal, directory
end
function filesystem:read(path)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = self:resolve(path)
	if not valid then
		return nil, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = self.root
	for i=1, #path-1 do
		node = node[path[i]]
		if type(node) ~= "table" then
			return nil, "not a directory", path, valid, absolute, traversal, directory
		end
	end
	node = node[path[#path]]
	return node, "no such file", path, valid, absolute, traversal, directory
end
function filesystem:write(path, data)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = self:resolve(path)
	if not valid then
		return false, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = self.root
	for i=1, #path-1 do
		node = node[path[i]]
		if type(node) ~= "table" then
			return false, "not a directory", path, valid, absolute, traversal, directory
		end
	end
	node[path[#path]] = data
	return true
end
function filesystem:mkdir(path, make_ascendants)
	local valid, absolute, traversal, directory
	path, valid, absolute, traversal, directory = self:resolve(path)
	if not valid then
		return false, "malformed path", path, valid, absolute, traversal, directory
	end
	local node = self.root
	for i=1, #path do
		local path_segment = path[i]
		local next_node = node[path_segment]
		if next_node == nil and (make_ascendants or i == #path) then
			next_node = {}
			node[path_segment] = next_node
		elseif type(next_node) ~= "table" then
			return false, "not a directory", path, valid, absolute, traversal, directory
		end
		node = next_node
	end
	return true
end
function filesystem:cd(path)
	local wd = self:resolve(path)
	local node = self.root
	for i=1, #wd do
		node = node[wd[i]]
		if type(node) ~= "table" then
			return false, "not a directory"
		end
	end
	self.cwd = wd
	return true
end

return filesystem
