local tiles = {}

local function defkind(name, spriteID, walkable)
	return {
		name = name,
		spriteID = spriteID,
		walkable = walkable,
	}
end

tiles.KIND = {
	defkind("ground", 1, true),
	defkind("wall", 2, false),
	defkind("wall", 3, false),
	defkind("wall", 4, false),
}

return tiles
