local unit = {}

local function defkind(spriteID, name, maxHealth, combatDamage, shotDamage, minShotRange, maxShotRange, isEnemy)
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

unit.KIND = {
	defkind(35, "Trooper", 2, 1, 2, 1, 2, false),
	defkind(34, "Captain", 3, 2, 2, 1, 2, false),
	defkind(33, "Sniper", 2, 1, 1, 2, 7, false),
	-- Enemy names are inspired on the https://en.wikipedia.org/wiki/Arachnid class
	defkind(25, "Opilion", 3, 1, 0, 0, 0, true),
	defkind(26, "Trombid", 2, 2, 1, 1, 3, true),
	defkind(27, "Xiphora", 1, 1, 1, 2, 4, true),
	defkind(28, "Teramon", 4, 2, 0, 0, 0, true),
	defkind(29, "Queen", 4, 2, 1, 1, 2, true),
}

local Unit = {}

function unit.newUnit(kind, gameX, gameY)
	local self = {}
	setmetatable(self, { __index = Unit })

	self.kind = kind
	self.health = kind.maxHealth

	self.gameX = gameX
	self.gameY = gameY

	self.hasMoved = false
	self.hasShot = false
	self.hasHit = false

	return self
end

function Unit:skipTurn()
	self.hasMoved = true
	self.hasShot = true
	self.hasHit = true
end

function Unit:resetTurn()
	self.hasMoved = false
	self.hasShot = false
	self.hasHit = false
end

function Unit:move(gameX, gameY)
	self.gameX = gameX
	self.gameY = gameY
	self.hasMoved = true
	self.hasShot = true
end

function Unit:hit(target)
	target:takeDamage(self.kind.combatDamage)
	self.hasShot = true
	self.hasMoved = true
	self.hasHit = true
end

function Unit:shoot(target)
	target:takeDamage(self.kind.shotDamage)
	self.hasShot = true
	self.hasMoved = true
	self.hasHit = true
end

function Unit:takeDamage(damage)
	if self.health <= damage then
		self.health = 0
	else
		self.health = self.health - damage
	end
end

function Unit:isAdversary(other)
	if not other then
		return false
	end
	return self.kind.isEnemy ~= other.kind.isEnemy
end

function Unit:isInShotRange(x, y)
	-- check whether is in the same axis as shooting can only be done in 4 directions
	if self.gameX ~= x and self.gameY ~= y then
		return false
	end

	if math.abs(x - self.gameX) < self.kind.minShotRange and math.abs(y - self.gameY) < self.kind.minShotRange then
		return false
	end

	return math.abs(x - self.gameX) <= self.kind.maxShotRange and math.abs(y - self.gameY) <= self.kind.maxShotRange
end

function Unit:isAlive()
	return self.health > 0
end

function Unit:hasRangedAttack()
	return self.kind.maxShotRange >= 2
end

return unit
