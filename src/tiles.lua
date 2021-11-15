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
	defkind("block", 41, false, true),
	defkind("wall", 2, false, true),
	defkind("wall", 3, false, true),
	defkind("wall", 4, false, true),
	defkind("wall", 5, false, true),
	defkind("wall", 9, false, true),
	defkind("wall", 10, false, true),
	defkind("wall", 11, false, true),
	defkind("wall", 12, false, true),
	defkind("wall", 49, false, true),
	defkind("door down", 50, false, true),
	defkind("wall", 51, false, true),
	defkind("wall", 57, false, true),
	defkind("door up", 58, false, true),
	defkind("wall", 59, false, true),
	defkind("block", 42, false, true),
}

return tiles
