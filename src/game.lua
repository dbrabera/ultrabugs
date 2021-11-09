local conf = require("conf")
local enemy = require("enemy")
local tiles = require("tiles")
local units = require("units")
local util = require("util")

local game = {}

local map = {
	{ 3, 2, 2, 2, 2, 2, 2, 2, 2, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 2, 2, 2, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 2, 2, 2, 2, 2, 2, 2, 2, 4 },
}

local TURN = {
	PLAYER = "player",
	ENEMY = "enemy",
}

local PHASE = {
	MOVEMENT = "movement",
	SHOOTING = "shooting",
	COMBAT = "combat",
}

local Game = {}

function game.newGame(screenX, screenY)
	local self = {}
	setmetatable(self, { __index = Game })

	self.screenX = screenX
	self.screenY = screenY

	self.enemy = enemy.newEnemy(self)

	self.playerUnits = {
		units.newUnit(units.KIND[1], 2, 2),
		units.newUnit(units.KIND[2], 4, 2),
		units.newUnit(units.KIND[3], 6, 3),
	}
	self.enemyUnits = {
		units.newUnit(units.KIND[4], 2, 4),
		units.newUnit(units.KIND[4], 7, 7),
	}
	self.selectedUnit = self.playerUnits[1]

	self.cursorGameX = -1
	self.cursorGameY = -1

	self.turn = TURN.PLAYER
	self.phase = PHASE.MOVEMENT

	return self
end

function Game:keypressed(key)
	if self.turn ~= TURN.PLAYER then
		return
	end

	if key == "space" then
		if self.selectedUnit then
			self:skipUnitPhase(self.selectedUnit)
		end

		local unit = self:nextPendingUnit()
		if unit then
			self.selectedUnit = unit
			return
		end

		if self.phase == PHASE.MOVEMENT then
			self.phase = PHASE.SHOOTING
		elseif self.phase == PHASE.SHOOTING then
			self.phase = PHASE.COMBAT
		elseif self.phase == PHASE.COMBAT then
			self.phase = PHASE.MOVEMENT
			self.turn = TURN.ENEMY
			for _, unit in ipairs(self.playerUnits) do
				unit:resetTurn()
			end
		end
	elseif key == "escape" then
		self.selectedUnit = nil
	end
end

function Game:mousepressed(x, y, button)
	if self.turn ~= TURN.PLAYER then
		return
	end

	if button == 2 then
		self.selectedUnit = nil
		return
	end

	if button ~= 1 then
		return
	end

	local gameX, gameY = self:gameCoords(x, y)

	local target = self:getUnitAt(gameX, gameY)

	if target and not target.kind.isEnemy then
		self.selectedUnit = target
		return
	end

	if not self.selectedUnit then
		return
	end

	if self.phase == PHASE.MOVEMENT then
		if self:canMove(self.selectedUnit, gameX, gameY) then
			self.selectedUnit:move(gameX, gameY)
		end
		return
	end

	if not target or not target.kind.isEnemy then
		return
	end

	if self.phase == PHASE.SHOOTING then
		if self:canShoot(self.selectedUnit, target) then
			self.selectedUnit:shoot(target)
		end
	elseif self.phase == PHASE.COMBAT then
		if self:canHit(self.selectedUnit, target) then
			self.selectedUnit:hit(target)
		end
	end
end

function Game:mousemoved(x, y)
	self.cursorGameX, self.cursorGameY = self:gameCoords(x, y)
end

function Game:update(dt)
	if self.turn ~= TURN.ENEMY then
		return
	end

	self.enemy:takeTurn()
	for _, unit in ipairs(self.enemyUnits) do
		unit:resetTurn()
	end

	self.turn = TURN.PLAYER
end

function Game:draw(sprites)
	for i = 0, conf.GRID_SIZE - 1 do
		for j = 0, conf.GRID_SIZE - 1 do
			local t = tiles.KIND[map[j + 1][i + 1]]
			sprites:draw(t.spriteID, self.screenX + i * conf.SPRITE_SIZE, self.screenY + j * conf.SPRITE_SIZE)
		end
	end

	local hoveredUnit = self:getUnitAt(self.cursorGameX, self.cursorGameY)

	local playerUnit = self.selectedUnit

	if not playerUnit then
		if hoveredUnit and not hoveredUnit.kind.isEnemy then
			playerUnit = hoveredUnit
		end
	end

	if playerUnit then
		for _, pos in ipairs(self:allowedActions(playerUnit)) do
			local x, y = self:screenCoords(pos.x, pos.y)
			sprites:draw(17, x, y)
		end
	end

	if self:isInbounds(self.cursorGameX, self.cursorGameY) then
		local x, y = self:screenCoords(self.cursorGameX, self.cursorGameY)
		util.drawRectangle("line", x, y, 16, 16, conf.WHITE)
	end

	if self.selectedUnit then
		local x, y = self:screenCoords(self.selectedUnit.gameX, self.selectedUnit.gameY)
		util.drawRectangle("line", x, y, 16, 16, conf.LIME)
	end

	for _, unit in ipairs(self.playerUnits) do
		self:drawUnit(sprites, unit)
	end

	for _, unit in ipairs(self.enemyUnits) do
		self:drawUnit(sprites, unit)
	end

	-- draw the indicators after the units to ensure that the overlap

	for _, unit in ipairs(self.playerUnits) do
		self:drawUnitIndicators(sprites, unit, unit == self.selectedUnit or unit == hoveredUnit)
	end

	for _, unit in ipairs(self.enemyUnits) do
		self:drawUnitIndicators(sprites, unit, unit == self.selectedUnit or unit == hoveredUnit)
	end

	util.drawText(self.phase, conf.WHITE, 0, 0)
end

function Game:drawUnit(sprites, unit)
	if not unit:isAlive() then
		return
	end

	local x, y = self:screenCoords(unit.gameX, unit.gameY)
	sprites:draw(unit.kind.spriteID, x, y)

	if unit.kind.isEnemy then
		return
	end
end

function Game:drawUnitIndicators(sprites, unit, withHealthBar)
	local x, y = self:screenCoords(unit.gameX, unit.gameY)

	if withHealthBar then
		self:drawHealthbar(x + (conf.SPRITE_SIZE / 2), y, unit.health, unit.kind.maxHealth, true)
	end

	if self:isPendingUnit(unit) then
		sprites:draw(18, x, y - conf.SPRITE_SIZE - (withHealthBar and 9 or 0))
	end
end

function Game:drawHealthbar(x, y, health, maxHealth, centered)
	local w = 4 * maxHealth + 1 - (1 * (maxHealth - 1))

	if centered then
		x = x - (w / 2)
	end

	util.drawRectangle("fill", x, y - 8, 4 * health, 5, conf.BLACK)
	util.drawRectangle("line", x, y - 8, w, 5, conf.WHITE)

	for i = 1, health do
		local xi, yi = x + 3 * (i - 1) + 1, y - 7
		util.drawRectangle("fill", xi, yi, 3, 3, conf.LIME)
		util.drawRectangle("line", xi, yi, 3, 3, conf.BLACK)
	end
end

function Game:allowedActions(actor)
	if self.phase == PHASE.MOVEMENT then
		return self:allowedMovements(actor)
	elseif self.phase == PHASE.COMBAT then
		return self:allowedHits(actor)
	elseif self.phase == PHASE.SHOOTING then
		return self:allowedShoots(actor)
	end
end

function Game:allowedMovements(actor)
	if actor.hasMoved then
		return {}
	end

	local res = {}

	for _, pos in ipairs(util.neighbors({ x = actor.gameX, y = actor.gameY })) do
		if self:isWalkable(pos.x, pos.y) then
			table.insert(res, pos)
		end
	end

	return res
end

function Game:allowedHits(actor)
	if actor.hasHit then
		return {}
	end

	local res = {}

	for _, pos in ipairs({
		{ -1, 0 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
	}) do
		local x, y = actor.gameX + pos[1], actor.gameY + pos[2]

		if self:isWalkable(x, y) or self:getUnitAt(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:allowedShoots(unit)
	if unit.hasShot then
		return {}
	end

	local res = {}

	for _, pos in ipairs({
		{ -2, 0 },
		{ 0, -2 },
		{ 0, 2 },
		{ 2, 0 },
		{ -3, 0 },
		{ 0, -3 },
		{ 0, 3 },
		{ 3, 0 },
	}) do
		local x, y = unit.gameX + pos[1], unit.gameY + pos[2]

		if self:isWalkable(x, y) or self:getUnitAt(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:isAllowed(source, target, positions)
	for _, pos in ipairs(positions) do
		if target.gameX == pos.x and target.gameY == pos.y then
			return true
		end
	end
	return false
end

function Game:canMove(actor, x, y)
	return self:isAllowed(actor, { gameX = x, gameY = y }, self:allowedMovements(actor))
end

function Game:canHit(actor, target)
	return self:isAllowed(actor, target, self:allowedHits(actor))
end

function Game:canShoot(actor, target)
	return self:isAllowed(actor, target, self:allowedShoots(actor))
end

function Game:isWalkable(gameX, gameY)
	if self:getUnitAt(gameX, gameY) then
		return false
	end
	return self:isInbounds(gameX, gameY) and tiles.KIND[map[gameY + 1][gameX + 1]].walkable
end

function Game:skipUnitPhase(unit)
	if self.phase == PHASE.MOVEMENT then
		unit.hasMoved = true
	elseif self.phase == PHASE.SHOOTING then
		unit.hasShot = true
	elseif self.phase == PHASE.COMBAT then
		unit.hasHit = true
	end
end

function Game:isPendingUnit(unit)
	if self.turn ~= TURN.PLAYER or unit.kind.isEnemy then
		return false
	end

	if self.phase == PHASE.MOVEMENT then
		return not unit.hasMoved
	elseif self.phase == PHASE.SHOOTING then
		return not unit.hasShot
	elseif self.phase == PHASE.COMBAT then
		return not unit.hasHit
	end
end

function Game:getUnitAt(gameX, gameY)
	for _, unit in ipairs(self.playerUnits) do
		if unit:isAlive() and unit.gameX == gameX and unit.gameY == gameY then
			return unit
		end
	end
	for _, unit in ipairs(self.enemyUnits) do
		if unit:isAlive() and unit.gameX == gameX and unit.gameY == gameY then
			return unit
		end
	end
end

function Game:isInbounds(gameX, gameY)
	return gameX >= 0 and gameY >= 0 and gameX < conf.GRID_SIZE and gameY < conf.GRID_SIZE
end

function Game:screenCoords(gameX, gameY)
	return self.screenX + gameX * conf.SPRITE_SIZE, self.screenY + gameY * conf.SPRITE_SIZE
end

function Game:gameCoords(screenX, screenY)
	local gameX = math.floor((screenX - self.screenX) / conf.SPRITE_SIZE)
	local gameY = math.floor((screenY - self.screenY) / conf.SPRITE_SIZE)
	return gameX, gameY
end

function Game:nextPendingUnit()
	for _, unit in ipairs(self.playerUnits) do
		if self:isPendingUnit(unit) then
			return unit
		end
	end
	return nil
end

return game
