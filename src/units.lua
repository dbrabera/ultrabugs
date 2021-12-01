local unit = {}

--- Defines a new kind of unit.
local function kind(spriteID, name, maxHealth, combatDamage, shotDamage, minShotRange, maxShotRange, isEnemy)
	return {
		spriteID = spriteID,
		name = name,
		maxHealth = maxHealth,
		combatDamage = combatDamage,
		shotDamage = shotDamage,
		minShotRange = minShotRange,
		maxShotRange = maxShotRange,
		isEnemy = isEnemy,
	}
end

--- The kind of units found in the game.
unit.KIND = {
	kind(35, "Trooper", 2, 1, 2, 2, 5, false),
	kind(34, "Captain", 3, 2, 3, 2, 3, false),
	kind(33, "Sniper", 2, 1, 1, 2, 7, false),
	-- Enemy names are inspired on the https://en.wikipedia.org/wiki/Arachnid class
	kind(25, "Opilion", 3, 1, 0, 0, 0, true),
	kind(26, "Trombid", 2, 2, 1, 1, 3, true),
	kind(27, "Xiphora", 1, 1, 1, 2, 4, true),
	kind(28, "Teramon", 4, 2, 0, 0, 0, true),
	kind(29, "Queen", 4, 2, 1, 1, 2, true),
}

--- A unit represents a playable character in the game. It has a position in the grid
-- and a set of attributes according to its kind.
local Unit = {}

--- Creates a new unit from the given kind.
function unit.newUnit(kind, x, y)
	local self = {}
	setmetatable(self, { __index = Unit })

	self.kind = kind
	self.health = kind.maxHealth

	self.x = x
	self.y = y

	self.hasMoved = false
	self.hasShot = false
	self.hasHit = false

	self.lastDamage = 0
	self.lastDamageAge = 0

	self.deathAge = 0

	return self
end

--- Handles the update callback.
function Unit:update(dt)
	self.lastDamageAge = self.lastDamageAge + dt

	if not self:isAlive() then
		self.deathAge = self.deathAge + dt
	end
end

--- Skips the unit turn setting all the action flags to true.
function Unit:skipTurn()
	self.hasMoved = true
	self.hasShot = true
	self.hasHit = true
end

--- Resets the unit turn setting all the action flags to false and
-- leaving the unit ready to take a new turn.
function Unit:resetTurn()
	self.hasMoved = false
	self.hasShot = false
	self.hasHit = false
end

--- Moves the unit to the given position. This assumes that
-- the caller already checked that the movement was valid.
function Unit:move(x, y)
	self.x = x
	self.y = y
	self.hasMoved = true
	self.hasShot = true
end

--- Hits the given target with the melee attack. This assumes
-- that the caller already checked that the attack was valid.
function Unit:hit(target)
	target:takeDamage(self.kind.combatDamage)
	self.hasShot = true
	self.hasMoved = true
	self.hasHit = true
end

--- Shoots the given target with the ranged attack. This assumes
-- that the caller already checked that the attack was valid.
function Unit:shoot(target)
	target:takeDamage(self.kind.shotDamage)
	self.hasShot = true
	self.hasMoved = true
	self.hasHit = true
end

--- Takes the given damage.
function Unit:takeDamage(damage)
	if self.health <= damage then
		self.lastDamage = self.health
		self.health = 0
	else
		self.health = self.health - damage
		self.lastDamage = damage
	end
	self.lastDamageAge = 0
end

--- Checks whether a given unit belongs to the adversary squad.
function Unit:isAdversary(other)
	if not other then
		return false
	end
	return self.kind.isEnemy ~= other.kind.isEnemy
end

--- Checks whether the given position is in range according to the kind ranged attack.
function Unit:isInShotRange(x, y)
	-- check whether is in the same axis as shooting can only be done in 4 directions
	if self.x ~= x and self.y ~= y then
		return false
	end

	if math.abs(x - self.x) < self.kind.minShotRange and math.abs(y - self.y) < self.kind.minShotRange then
		return false
	end

	return math.abs(x - self.x) <= self.kind.maxShotRange and math.abs(y - self.y) <= self.kind.maxShotRange
end

--- Checks whether the unit is alive.
function Unit:isAlive()
	return self.health > 0
end

function Unit:hasRangedAttack()
	return self.kind.maxShotRange >= 2
end

--- Checks whetherthe unit belongs to the enemy.
function Unit:isEnemy()
	return self.kind.isEnemy
end

--- Checks whether the unit belongs to the player.
function Unit:isPlayer()
	return not self.kind.isEnemy
end

return unit
