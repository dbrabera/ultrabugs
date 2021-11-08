local unit = {}

local function defkind(spriteID, name, health, combatDamage, rangedDamage)
	return {
		spriteID = spriteID,
		name = name,
		health = health,
		combatDamage = combatDamage,
		rangedDamage = rangedDamage,
	}
end

unit.KIND = {
	defkind(9, "marine", 2, 1, 2),
	defkind(10, "marine captain", 2, 2, 2),
	defkind(11, "marine", 2, 1, 1),
	defkind(25, "bug", 2, 1, 0),
}

local Unit = {}

function unit.newUnit(kind, gameX, gameY)
	local self = {}
	setmetatable(self, { __index = Unit })

	self.kind = kind
	self.health = kind.health

	self.gameX = gameX
	self.gameY = gameY

	return self
end

function Unit:move(gameX, gameY)
	self.gameX = gameX
	self.gameY = gameY
end

function Unit:hit(target)
	target:takeDamage(self.kind.combatDamage)
end

function Unit:shoot(target)
	target:takeDamage(self.kind.rangedDamage)
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
