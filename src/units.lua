local unit = {}

local function defkind(spriteID, name, maxHealth, combatDamage, rangedDamage, isEnemy)
	return {
		spriteID = spriteID,
		name = name,
		maxHealth = maxHealth,
		combatDamage = combatDamage,
		rangedDamage = rangedDamage,
		isEnemy = isEnemy,
	}
end

unit.KIND = {
	defkind(9, "marine", 2, 1, 2, false),
	defkind(10, "marine captain", 2, 2, 2, false),
	defkind(11, "marine", 2, 1, 1, false),
	defkind(25, "bug", 1, 1, 0, true),
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
end

function Unit:hit(target)
	print(self.kind.name .. " hits " .. target.kind.name)
	target:takeDamage(self.kind.combatDamage)
	self.hasHit = true
end

function Unit:shoot(target)
	print(self.kind.name .. " shoots at " .. target.kind.name)
	target:takeDamage(self.kind.rangedDamage)
	self.hasShot = true
end

function Unit:takeDamage(damage)
	print(self.kind.name .. " takes " .. damage .. " damage")
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
