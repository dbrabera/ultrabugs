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

game.ACTION = {
	MOVE = "move",
	SHOOT = "shoot",
	FIGHT = "fight",
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
			unit:resetTurn()
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
	self.action = game.ACTION.MOVE
	self.turnCount = 0

	return self
end

function Game:keypressed(key)
	if self.turn ~= game.TURN.PLAYER then
		return
	end

	if key == "space" then
		self:endPlayerTurn()
	elseif key == "1" then
		if self.selectedUnit then
			self.action = game.ACTION.MOVE
		end
	elseif key == "2" then
		if self.selectedUnit then
			self.action = game.ACTION.SHOOT
		end
	elseif key == "3" then
		if self.selectedUnit then
			self.action = game.ACTION.FIGHT
		end
	elseif key == "escape" then
		self.selectedUnit = nil
	end
end

function Game:endPlayerTurn()
	self.action = game.ACTION.MOVE
	self.selectedUnit = nil
	self.turn = game.TURN.ENEMY
	for _, unit in ipairs(self.playerUnits) do
		unit:resetTurn()
	end
	self.turnCount = self.turnCount + 1
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
		self.action = game.ACTION.MOVE
		return
	end

	if not self.selectedUnit then
		return
	end

	if self.action == game.ACTION.MOVE then
		if self:canMove(self.selectedUnit, gameX, gameY) then
			self.selectedUnit:move(gameX, gameY)
		end
		return
	end

	if not target or not target.kind.isEnemy then
		return
	end

	if self.action == game.ACTION.SHOOT then
		if self:canShoot(self.selectedUnit, target) then
			self.selectedUnit:shoot(target)
		end
	elseif self.action == game.ACTION.FIGHT then
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
			if self.action == game.ACTION.SHOOT then
				color = conf.YELLOW
			elseif self.action == game.ACTION.FIGHT then
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

	-- draw the shadows before the units to ensure that they are below them
	for _, unit in ipairs(self.playerUnits) do
		self:drawUnitShadow(sprites, unit)
	end

	for _, unit in ipairs(self.enemyUnits) do
		self:drawUnitShadow(sprites, unit)
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

function Game:drawUnitShadow(sprites, unit)
	if not unit:isAlive() then
		return
	end

	local x, y = self:screenCoords(unit.gameX, unit.gameY)
	sprites:draw(17, x, y)
end

function Game:drawUnit(sprites, unit)
	if not unit:isAlive() then
		return
	end

	local x, y = self:screenCoords(unit.gameX, unit.gameY)
	sprites:draw(unit.kind.spriteID, x, y - 3)

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
		game.drawHealthbar(x + (conf.SPRITE_SIZE / 2), y - 3, unit.health, unit.kind.maxHealth, true)
	end

	if self:isPendingUnit(unit) then
		sprites:draw(18, x, y - conf.SPRITE_SIZE - (withHealthBar and 9 or 0) - 3)
	end
end

function Game:allowedActions(unit)
	if self.action == game.ACTION.MOVE then
		return self:allowedMovements(unit)
	elseif self.action == game.ACTION.FIGHT then
		return self:allowedHits(unit)
	elseif self.action == game.ACTION.SHOOT then
		return self:allowedShots(unit)
	end
end

function Game:allowedMovements(unit)
	if unit.hasMoved then
		return {}
	end

	local res = {}

	for _, pos in ipairs(util.neighbors({ x = unit.gameX, y = unit.gameY })) do
		if self:isWalkable(pos.x, pos.y) and self:isEmpty(pos.x, pos.y) then
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
			return self:isSolid(p.x, p.y)
		end)) do
			local target = self:getUnitAt(pos.x, pos.y)

			if target and target ~= unit then
				if unit:isInShotRange(pos.x, pos.y) and unit:isAdversary(target) then
					table.insert(res, pos)
				end
				-- blocks the rest of the line
				break
			end

			if unit:isInShotRange(pos.x, pos.y) then
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

function Game:isWalkable(x, y)
	return self:isInbounds(x, y) and tiles.KIND[self.map[y + 1][x + 1]].walkable
end

function Game:isEmpty(x, y)
	return not self:getUnitAt(x, y)
end

--- Checks whether a tile is solid and blocks the line of sight.
function Game:isSolid(x, y)
	return not self:isInbounds(x, y) or tiles.KIND[self.map[y + 1][x + 1]].solid
end

function Game:isPendingUnit(unit)
	if self.turn ~= game.TURN.PLAYER or unit.kind.isEnemy or not unit:isAlive() then
		return false
	end
	return not unit.hasMoved
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

function Game:stats()
	local killCount = 0

	for _, unit in ipairs(self.enemyUnits) do
		if not unit:isAlive() then
			killCount = killCount + 1
		end
	end

	return {
		turnCount = self.turnCount,
		killCount = killCount,
	}
end

return game
