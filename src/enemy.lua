local util = require("util")

local enemy = {}

local Enemy = {}

function enemy.newEnemy(game)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.game = game

	return self
end

function Enemy:takeTurn()
	for _, unit in ipairs(self.game.enemyUnits) do
		if unit:isAlive() then
			local _, playerPath = self:findClosestPlayerUnit(unit)

			local next = table.remove(playerPath)
			if self.game:isWalkable(next.x, next.y) then
				unit:move(next.x, next.y)
			end
		end
	end
end

function Enemy:findClosestPlayerUnit(unit)
	local minPath = nil
	local closestUnit = nil

	for _, playerUnit in ipairs(self.game.playerUnits) do
		local path = self:findPath(unit, playerUnit)
		if path and (not minPath or #path < #minPath) then
			minPath = path
			closestUnit = playerUnit
		end
	end

	return closestUnit, minPath
end

function Enemy:findPath(source, target)
	return util.findPath({ x = source.gameX, y = source.gameY }, { x = target.gameX, y = target.gameY }, function(pos)
		return self.game:isWalkable(pos.x, pos.y)
	end)
end

return enemy
