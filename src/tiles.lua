local tiles = {}

local function defkind(name, spriteID, walkable, solid)
	return {
		name = name,
		spriteID = spriteID,
		walkable = walkable,
		solid = solid,
	}
end

tiles.KIND = {
	defkind("ground", 1, true, false),
	defkind("wall", 2, false, true),
	defkind("wall", 3, false, true),
	defkind("wall", 4, false, true),
}

return tiles
