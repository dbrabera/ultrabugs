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
			self:useUnit(unit)
		end
	end
end

function Enemy:useUnit(unit)
	local target, playerPath = self:findClosestPlayerUnit(unit)
	local next = table.remove(playerPath)

	if self.game:isAllowed(target, self.game:allowedShots(unit)) then
		unit:shoot(target)
		return
	end

	if self.game:isWalkable(next.x, next.y) then
		unit:move(next.x, next.y)
	end

	if self.game:isAllowed(target, self.game:allowedHits(unit)) then
		unit:hit(target)
	end
end

--- Returns the closest player unit. If two player units are at the same distance it returns the one
-- with less health.
function Enemy:findClosestPlayerUnit(unit)
	local minPath = nil
	local closestUnit = nil

	for _, playerUnit in ipairs(self.game.playerUnits) do
		if playerUnit:isAlive() then
			local path = self:findPath(unit, playerUnit)

			if path and (not minPath or #path < #minPath or playerUnit.health < closestUnit.health) then
				minPath = path
				closestUnit = playerUnit
			end
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
