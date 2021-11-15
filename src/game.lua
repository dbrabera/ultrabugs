local conf = require("conf")
local enemy = require("enemy")
local levels = require("levels")
local tiles = require("tiles")
local units = require("units")
local util = require("util")

local game = {}

game.TURN = {
	PLAYER = "player",
	ENEMY = "enemy",
}

game.PHASE = {
	MOVEMENT = "movement",
	SHOOTING = "shooting",
	COMBAT = "combat",
}

local Game = {}

function game.newGame(lvl, screenX, screenY, playerUnits)
	local self = {}
	setmetatable(self, { __index = Game })

	if not playerUnits then
		playerUnits = {
			units.newUnit(units.KIND[2], 2, 1),
			units.newUnit(units.KIND[1], 1, 1),
			units.newUnit(units.KIND[3], 3, 1),
		}
	else
		for _, unit in ipairs(playerUnits) do
			unit.resetTurn()
		end
	end

	self.screenX = screenX
	self.screenY = screenY

	self.enemy = enemy.newEnemy(self)

	self.map, self.playerUnits, self.enemyUnits = levels.build(lvl, playerUnits)
	self.selectedUnit = self.playerUnits[1]

	self.cursorGameX = -1
	self.cursorGameY = -1

	self.turn = game.TURN.PLAYER
	self.phase = game.PHASE.MOVEMENT

	return self
end

function Game:keypressed(key)
	if self.turn ~= game.TURN.PLAYER then
		return
	end

	if key == "space" then
		if self.selectedUnit then
			self:skipUnitPhase(self.selectedUnit)
		end

		self.selectedUnit = self:nextPendingUnit()
		if self.selectedUnit then
			return
		end

		if self.phase == game.PHASE.MOVEMENT then
			self.phase = game.PHASE.SHOOTING
			self.selectedUnit = self:nextPendingUnit()
		elseif self.phase == game.PHASE.SHOOTING then
			self.phase = game.PHASE.COMBAT
			self.selectedUnit = self:nextPendingUnit()
			if not self.selectedUnit then
				self:endPlayerTurn()
			end
		elseif self.phase == game.PHASE.COMBAT then
			self:endPlayerTurn()
		end

		return
	elseif key == "escape" then
		self.selectedUnit = nil
	end
end

function Game:endPlayerTurn()
	self.phase = game.PHASE.MOVEMENT
	self.turn = game.TURN.ENEMY
	for _, unit in ipairs(self.playerUnits) do
		unit:resetTurn()
	end
end

function Game:mousepressed(x, y, button)
	if self.turn ~= game.TURN.PLAYER then
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

	if self.phase == game.PHASE.MOVEMENT then
		if self:canMove(self.selectedUnit, gameX, gameY) then
			self.selectedUnit:move(gameX, gameY)
		end
		return
	end

	if not target or not target.kind.isEnemy then
		return
	end

	if self.phase == game.PHASE.SHOOTING then
		if self:canShoot(self.selectedUnit, target) then
			self.selectedUnit:shoot(target)
		end
	elseif self.phase == game.PHASE.COMBAT then
		if self:canHit(self.selectedUnit, target) then
			self.selectedUnit:hit(target)
		end
	end
end

function Game:mousemoved(x, y)
	self.cursorGameX, self.cursorGameY = self:gameCoords(x, y)
end

function Game:update(dt)
	if self.turn ~= game.TURN.ENEMY then
		return
	end

	self.enemy:takeTurn()
	for _, unit in ipairs(self.enemyUnits) do
		unit:resetTurn()
	end

	self.turn = game.TURN.PLAYER
	self.selectedUnit = self:nextPendingUnit()
end

function Game:draw(sprites)
	for i = 0, conf.GRID_SIZE - 1 do
		for j = 0, conf.GRID_SIZE - 1 do
			local t = tiles.KIND[self.map[j + 1][i + 1]]
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

			local color = conf.LIME
			if self.phase == game.PHASE.SHOOTING then
				color = conf.YELLOW
			elseif self.phase == game.PHASE.COMBAT then
				color = conf.RED
			end

			util.drawRectangle("fill", x, y, 16, 16, color, 0.4)
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

function game.drawHealthbar(x, y, health, maxHealth, centered, borderColor)
	borderColor = borderColor or conf.WHITE
	local w = 4 * maxHealth + 1 - (1 * (maxHealth - 1))

	if centered then
		x = x - (w / 2)
	end

	util.drawRectangle("fill", x, y - 8, 4 * health, 5, conf.BLACK)
	util.drawRectangle("line", x, y - 8, w, 5, borderColor)

	for i = 1, health do
		local xi, yi = x + 3 * (i - 1) + 1, y - 7
		util.drawRectangle("fill", xi, yi, 3, 3, conf.LIME)
		util.drawRectangle("line", xi, yi, 3, 3, conf.BLACK)
	end
end

function Game:drawUnitIndicators(sprites, unit, withHealthBar)
	local x, y = self:screenCoords(unit.gameX, unit.gameY)

	if withHealthBar then
		game.drawHealthbar(x + (conf.SPRITE_SIZE / 2), y, unit.health, unit.kind.maxHealth, true)
	end

	if self:isPendingUnit(unit) then
		sprites:draw(18, x, y - conf.SPRITE_SIZE - (withHealthBar and 9 or 0))
	end
end

function Game:allowedActions(unit)
	if self.phase == game.PHASE.MOVEMENT then
		return self:allowedMovements(unit)
	elseif self.phase == game.PHASE.COMBAT then
		return self:allowedHits(unit)
	elseif self.phase == game.PHASE.SHOOTING then
		return self:allowedShots(unit)
	end
end

function Game:allowedMovements(unit)
	if unit.hasMoved then
		return {}
	end

	local res = {}

	for _, pos in ipairs(util.neighbors({ x = unit.gameX, y = unit.gameY })) do
		if self:isWalkable(pos.x, pos.y) then
			table.insert(res, pos)
		end
	end

	return res
end

function Game:allowedHits(unit)
	if unit.hasHit then
		return {}
	end

	local res = {}

	for _, pos in ipairs({
		{ -1, 0 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
	}) do
		local x, y = unit.gameX + pos[1], unit.gameY + pos[2]

		if self:getUnitAt(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:allowedShots(unit)
	if unit.hasShot then
		return {}
	end

	local res = {}
	for _, delta in ipairs({
		{ unit.kind.maxShotRange, 0 },
		{ -unit.kind.maxShotRange, 0 },
		{ 0, unit.kind.maxShotRange },
		{ 0, -unit.kind.maxShotRange },
	}) do
		local x, y = unit.gameX + delta[1], unit.gameY + delta[2]

		for _, pos in ipairs(util.los({ x = unit.gameX, y = unit.gameY }, { x = x, y = y }, function(p)
			return not self:isInbounds(p.x, p.y) or tiles.KIND[self.map[p.y + 1][p.x + 1]].solid
		end)) do
			if
				math.abs(pos.x - unit.gameX) >= unit.kind.minShotRange
				or math.abs(pos.y - unit.gameY) >= unit.kind.minShotRange
			then
				table.insert(res, pos)
			end
		end
	end

	return res
end

function Game:isAllowed(target, positions)
	for _, pos in ipairs(positions) do
		if target.gameX == pos.x and target.gameY == pos.y then
			return true
		end
	end
	return false
end

function Game:canMove(unit, x, y)
	return self:isAllowed({ gameX = x, gameY = y }, self:allowedMovements(unit))
end

function Game:canHit(unit, target)
	return self:isAllowed(target, self:allowedHits(unit))
end

function Game:canShoot(unit, target)
	return self:isAllowed(target, self:allowedShots(unit))
end

function Game:isInCombat(unit)
	for _, pos in ipairs(self:allowedHits(unit)) do
		local target = self:getUnitAt(pos.x, pos.y)
		if target and target.kind.isEnemy then
			return true
		end
	end
	return false
end

function Game:isWalkable(gameX, gameY)
	if self:getUnitAt(gameX, gameY) then
		return false
	end
	return self:isInbounds(gameX, gameY) and tiles.KIND[self.map[gameY + 1][gameX + 1]].walkable
end

function Game:skipUnitPhase(unit)
	if self.phase == game.PHASE.MOVEMENT then
		unit.hasMoved = true
	elseif self.phase == game.PHASE.SHOOTING then
		unit.hasShot = true
	elseif self.phase == game.PHASE.COMBAT then
		unit.hasHit = true
	end
end

function Game:isPendingUnit(unit)
	if self.turn ~= game.TURN.PLAYER or unit.kind.isEnemy or not unit:isAlive() then
		return false
	end

	local isInCombat = self:isInCombat(unit)

	if self.phase == game.PHASE.MOVEMENT then
		return not unit.hasMoved
	elseif self.phase == game.PHASE.SHOOTING then
		return not unit.hasShot and not isInCombat
	elseif self.phase == game.PHASE.COMBAT then
		return not unit.hasHit and isInCombat
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

function Game:isVictory()
	for _, unit in ipairs(self.enemyUnits) do
		if unit:isAlive() then
			return false
		end
	end
	return true
end

function Game:isGameOver()
	for _, unit in ipairs(self.playerUnits) do
		if unit:isAlive() then
			return false
		end
	end
	return true
end

return game
