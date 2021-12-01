local tiles = {}

--- Defines a new kind of tile.
local function kind(name, spriteID, walkable, solid)
	return {
		name = name,
		spriteID = spriteID,
		walkable = walkable,
		solid = solid,
	}
end

--- The kind of tiles found in the game.
tiles.KIND = {
	kind("ground", 1, true, false),
	kind("block", 41, false, true),
	kind("wall", 2, false, true),
	kind("wall", 3, false, true),
	kind("wall", 4, false, true),
	kind("wall", 5, false, true),
	kind("wall", 9, false, true),
	kind("wall", 10, false, true),
	kind("wall", 11, false, true),
	kind("wall", 12, false, true),
	kind("wall", 49, false, true),
	kind("door down", 50, false, true),
	kind("wall", 51, false, true),
	kind("wall", 57, false, true),
	kind("door up", 58, false, true),
	kind("wall", 59, false, true),
	kind("block", 42, false, true),
	kind("pool", 6, false, false),
	kind("pool", 7, false, false),
	kind("pool", 8, false, false),
	kind("pool", 14, false, false),
	kind("pool", 15, false, false),
	kind("pool", 16, false, false),
	kind("ground", 18, true, false),
}

return tiles
