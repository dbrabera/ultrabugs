local units = require("units")

local levels = {}

local LEVELS = {
	{
		map = {
			{ 09, 03, 03, 03, 14, 15, 16, 03, 03, 10 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 02, 02, 02, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 07, 11, 12, 13, 06, 06, 06, 06, 06, 08 },
		},
		players = {
			{ 5, 1 },
			{ 4, 1 },
			{ 6, 1 },
		},
		enemies = {
			{ 4, 3, 7 },
			{ 4, 7, 7 },
		},
	},
	{
		map = {
			{ 09, 14, 15, 16, 03, 03, 03, 03, 03, 10 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 04, 01, 17, 01, 01, 02, 17, 01, 01, 05 },
			{ 04, 02, 02, 01, 01, 01, 17, 01, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 02, 02, 01, 05 },
			{ 04, 01, 01, 01, 01, 01, 01, 01, 01, 05 },
			{ 07, 11, 12, 13, 06, 06, 06, 06, 06, 08 },
		},
		players = {
			{ 2, 1 },
			{ 1, 1 },
			{ 3, 1 },
		},
		enemies = {
			{ 4, 1, 7 },
			{ 4, 7, 8 },
			{ 4, 3, 8 },
		},
	},
}

levels.MAX_LEVEL = #LEVELS

function levels.build(lvl, playerUnits)
	local enemyUnits = {}

	for _, u in ipairs(LEVELS[lvl].enemies) do
		table.insert(enemyUnits, units.newUnit(units.KIND[u[1]], u[2], u[3]))
	end

	for i, unit in ipairs(playerUnits) do
		unit.gameX = LEVELS[lvl].players[i][1]
		unit.gameY = LEVELS[lvl].players[i][2]
	end

	return LEVELS[lvl].map, playerUnits, enemyUnits
end

return levels
