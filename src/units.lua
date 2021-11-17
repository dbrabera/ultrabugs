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
	defkind(33, "Sniper", 2, 1, 1, 2, 4, false),
	-- Enemy names are inspired on the https://en.wikipedia.org/wiki/Arachnid class
	defkind(25, "Opilion", 3, 1, 0, 0, 0, true),
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

function Unit:isAlive()
	return self.health > 0
end

return unit
