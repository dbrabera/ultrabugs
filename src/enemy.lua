local util = require("util")

local enemy = {}

--- The enemy controls the actions of the enemy squad units. At the moment it implements
-- a fairly simplistc stateless AI that will just rush the units towards the player.
--
-- See: http://www.roguebasin.com/index.php/Roguelike_Intelligence_-_Stateless_AIs
local Enemy = {}

--- Creates a new enemy.
function enemy.newEnemy(game)
	local self = {}
	setmetatable(self, { __index = Enemy })

	self.game = game
	return self
end

--- Takes a turn for one of the units. If there are no units with free actions
-- it returns true to indicate that the enemy turn was completed. The turns are
-- taking step by step for each unit to allow time to draw the movements.
function Enemy:takeTurn(dt)
	for _, unit in ipairs(self.game.enemyUnits) do
		if self:doUnitAction(unit) then
			self.lastActionAgo = 0
			return false
		end
	end
	return true
end

--- Uses the unit to do an action. It returns a boolean indicating whether any action
-- was done or the unit was skipped.
function Enemy:doUnitAction(unit)
	if not self.game:isPendingUnit(unit) then
		return false
	end

	local target, playerPath = self:findClosestPlayerUnit(unit)
	if not playerPath then
		unit:skipTurn()
		return false
	end

	local next = table.remove(playerPath)

	if not unit.hasShot and self.game:isInPositions(target, self.game:allowedShots(unit)) then
		unit:shoot(target)
		return true
	end

	if not unit.hasMoved and self.game:isWalkable(next.x, next.y) and self.game:isEmpty(next.x, next.y) then
		unit:move(next.x, next.y)
		return true
	else
		unit.hasMoved = true
	end

	if not unit.hasHit and self.game:isInPositions(target, self.game:allowedHits(unit)) then
		unit:hit(target)
		return true
	else
		unit.hasHit = true
	end

	return false
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

--- Finds a path from the given source unit to the target.
function Enemy:findPath(source, target)
	return util.findPath({ x = source.x, y = source.y }, { x = target.x, y = target.y }, function(pos)
		return self.game:isWalkable(pos.x, pos.y)
	end)
end

return enemy
