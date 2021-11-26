local conf = require("conf")
local enemy = require("enemy")
local levels = require("levels")
local tiles = require("tiles")
local units = require("units")
local util = require("util")

local game = {}

-- Time to wait on a *_TRANSITION state
local TRANSITION_DELAY_SECONDS = 0.6
-- Time to wait on the ENEMY_MOVE state
local ENEMY_MOVE_DELAY_SECONDS = 0.3

game.STATE = {
	START_TRANSITION = "start_transition",
	ENEMY_MOVE = "enemy_move",
	ENEMY_TURN = "enemy_turn",
	ENEMY_TURN_TRANSITION = "enemy_turn_transition",
	GAME_OVER = "game_over",
	GAME_OVER_TRANSITION = "game_over_transition",
	PLAYER_TURN = "player_turn",
	PLAYER_TURN_TRANSITION = "player_turn_transition",
	VICTORY = "victory",
	VICTORY_TRANSITION = "victory_transition",
}

game.ACTION = {
	MOVE = "move",
	SHOOT = "shoot",
	HIT = "hit",
}

local Game = {}

function game.newGame(lvl, playerUnits)
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

	self.enemy = enemy.newEnemy(self)

	self.map, self.playerUnits, self.enemyUnits = levels.build(lvl, playerUnits)
	self.selectedUnit = nil

	self.state = game.STATE.START_TRANSITION
	self.stateSince = 0

	self.action = game.ACTION.MOVE
	self.turnCount = 0

	return self
end

function Game:keypressed(key)
	if self.state ~= game.STATE.PLAYER_TURN then
		return
	end

	if key == "space" then
		self:endPlayerTurn()
	elseif key == "1" then
		self:selectAction(game.ACTION.MOVE)
	elseif key == "2" then
		self:selectAction(game.ACTION.SHOOT)
	elseif key == "3" then
		self:selectAction(game.ACTION.HIT)
	elseif key == "escape" then
		self.selectedUnit = nil
	end
end

function Game:selectAction(action)
	if self.state ~= game.STATE.PLAYER_TURN or not self.selectedUnit then
		return
	end
	self.action = action
end

function Game:endPlayerTurn()
	self.action = game.ACTION.MOVE
	self.selectedUnit = nil

	for _, unit in ipairs(self.playerUnits) do
		unit:resetTurn()
	end
	self.turnCount = self.turnCount + 1

	if self:isVictory() then
		self:advaceState(game.STATE.VICTORY_TRANSITION)
	else
		self:advaceState(game.STATE.ENEMY_TURN_TRANSITION)
	end
end

function Game:mousepressed(x, y, button)
	if self.state ~= game.STATE.PLAYER_TURN then
		return
	end

	if button == 2 then
		self.selectedUnit = nil
		self.action = game.ACTION.MOVE
		return
	end

	if button ~= 1 then
		return
	end

	local target = self:getUnitAt(x, y)

	if target and not target.kind.isEnemy then
		self.selectedUnit = target
		self.action = game.ACTION.MOVE
		return
	end

	if not self.selectedUnit then
		return
	end

	if self.action == game.ACTION.MOVE then
		if self:canMove(self.selectedUnit, x, y) then
			self.selectedUnit:move(x, y)
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
	elseif self.action == game.ACTION.HIT then
		if self:canHit(self.selectedUnit, target) then
			self.selectedUnit:hit(target)
		end
	end
end

function Game:update(dt)
	self.stateSince = self.stateSince + dt

	if self.state == game.STATE.START_TRANSITION then
		if self.stateSince >= TRANSITION_DELAY_SECONDS then
			self:advaceState(game.STATE.PLAYER_TURN)
		end
	elseif self.state == game.STATE.PLAYER_TURN then
		if self:isVictory() then
			self:advaceState(game.STATE.VICTORY_TRANSITION)
		end
		return
	elseif self.state == game.STATE.ENEMY_TURN then
		if self.enemy:takeTurn(dt) then
			for _, unit in ipairs(self.enemyUnits) do
				unit:resetTurn()
			end

			if self:isGameOver() then
				self:advaceState(game.STATE.GAME_OVER_TRANSITION)
			else
				self:advaceState(game.STATE.PLAYER_TURN_TRANSITION)
			end

			return
		end
		self:advaceState(game.STATE.ENEMY_MOVE)
	elseif self.state == game.STATE.ENEMY_MOVE then
		if self.stateSince >= ENEMY_MOVE_DELAY_SECONDS then
			self:advaceState(game.STATE.ENEMY_TURN)
		end
	elseif self.state == game.STATE.PLAYER_TURN_TRANSITION then
		if self.stateSince >= TRANSITION_DELAY_SECONDS then
			self:advaceState(game.STATE.PLAYER_TURN)
		end
	elseif self.state == game.STATE.ENEMY_TURN_TRANSITION then
		if self.stateSince >= TRANSITION_DELAY_SECONDS then
			self:advaceState(game.STATE.ENEMY_TURN)
		end
	elseif self.state == game.STATE.GAME_OVER_TRANSITION then
		if self.stateSince >= TRANSITION_DELAY_SECONDS then
			self:advaceState(game.STATE.GAME_OVER)
		end
	elseif self.state == game.STATE.VICTORY_TRANSITION then
		if self.stateSince >= TRANSITION_DELAY_SECONDS then
			self:advaceState(game.STATE.VICTORY)
		end
	end
end

function Game:advaceState(state)
	self.state = state
	self.stateSince = 0
end

function Game:isMoving()
	return self.action == game.ACTION.MOVE
end

function Game:isShooting()
	return self.action == game.ACTION.SHOOT
end

function Game:isHitting()
	return self.action == game.ACTION.HIT
end

function Game:allowedActions(unit)
	if self:isMoving() then
		return self:allowedMovements(unit)
	elseif self:isHitting() then
		return self:allowedHits(unit)
	elseif self:isShooting() then
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
	if self.state ~= game.STATE.PLAYER_TURN or unit.kind.isEnemy or not unit:isAlive() then
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
