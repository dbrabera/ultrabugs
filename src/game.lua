local conf = require("conf")
local enemy = require("enemy")
local levels = require("levels")
local tiles = require("tiles")
local units = require("units")
local util = require("util")

local game = {}

--- Time to wait on a *_TRANSITION state
local TRANSITION_DELAY_SECONDS = 0.6
--- Time to wait on the ENEMY_MOVE state
local ENEMY_MOVE_DELAY_SECONDS = 0.3

--- The states that the game can reach. Transition states
-- are used to time animations and effects.
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

--- The actions that the player can perform.
game.ACTION = {
	MOVE = "move",
	SHOOT = "shoot",
	HIT = "hit",
}

--- The game implements the game logic for a given level, keeping
-- track of the state and handling the player and enemy actions.
-- A new game instance must be created for each level.
local Game = {}

--- Creates a new game.
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

--- Handles the keypressed callback.
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

--- Ends the player turn and transitions to the next game state.
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

--- Handles the mousepressed callback.
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

	if self:isMoving() then
		if self:canMove(self.selectedUnit, x, y) then
			self.selectedUnit:move(x, y)
		end
		return
	end

	if not target or not target.kind.isEnemy then
		return
	end

	if self:isShooting() and self:canShoot(self.selectedUnit, target) then
		self.selectedUnit:shoot(target)
	elseif self:isHitting() and self:canHit(self.selectedUnit, target) then
		self.selectedUnit:hit(target)
	end
end

--- Handles the update callback.
function Game:update(dt)
	self.stateSince = self.stateSince + dt

	for _, unit in ipairs(self.playerUnits) do
		unit:update(dt)
	end

	for _, unit in ipairs(self.enemyUnits) do
		unit:update(dt)
	end

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

--- Advances the game to the given state.
function Game:advaceState(state)
	self.state = state
	self.stateSince = 0
end

--- Checks whether the current selected action is MOVE.
function Game:isMoving()
	return self.action == game.ACTION.MOVE
end

--- Checks whether the current selected action is SHOOT.
function Game:isShooting()
	return self.action == game.ACTION.SHOOT
end

--- Checks whether the current selected action is HIT.
function Game:isHitting()
	return self.action == game.ACTION.HIT
end

--- Returns the damage that the selected unit will do according
-- to the current action. If there is no selected unit
-- or action it returns zero.
function Game:getActionDamage()
	if not self.selectedUnit then
		return 0
	end

	if self:isShooting() then
		return self.selectedUnit.kind.shotDamage
	elseif self:isHitting() then
		return self.selectedUnit.kind.combatDamage
	end

	return 0
end

--- Checks whether the position can be targeted according to the
-- selected unit and action
function Game:canTarget(x, y)
	if not self.selectedUnit then
		return false
	end

	if self:isMoving() then
		return self:canMove(self.selectedUnit, x, y)
	end

	local target = self:getUnitAt(x, y)
	if not target or not target.kind.isEnemy then
		return false
	end

	if self:isShooting() then
		return self:canShoot(self.selectedUnit, target)
	elseif self:isHitting() then
		return self:canHit(self.selectedUnit, target)
	end
end

--- Returns the positions to which the unit is allowed to act according to the selected action.
function Game:allowedActions(unit)
	if self:isMoving() then
		return self:allowedMovements(unit)
	elseif self:isHitting() then
		return self:allowedHits(unit)
	elseif self:isShooting() then
		return self:allowedShots(unit)
	end
end

--- Returns the positions to which the unit is allowed to move.
function Game:allowedMovements(unit)
	if unit.hasMoved then
		return {}
	end

	local res = {}

	for _, pos in ipairs(util.neighbors({ x = unit.x, y = unit.y })) do
		if self:isWalkable(pos.x, pos.y) and self:isEmpty(pos.x, pos.y) then
			table.insert(res, pos)
		end
	end

	return res
end

--- Returns the positions to which the unit is allowed to hit.
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
		local x, y = unit.x + pos[1], unit.y + pos[2]
		if self:isWalkable(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

--- Returns the positions to which the unit is allowed to shoot.
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
		local x, y = unit.x + delta[1], unit.y + delta[2]

		for _, pos in ipairs(util.los({ x = unit.x, y = unit.y }, { x = x, y = y }, function(p)
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

--- Checks whether the target is in one of the given positions
function Game:isInPositions(target, positions)
	for _, pos in ipairs(positions) do
		if target.x == pos.x and target.y == pos.y then
			return true
		end
	end
	return false
end

--- Checks whether the unit can move to the given position.
function Game:canMove(unit, x, y)
	return self:isInPositions({ x = x, y = y }, self:allowedMovements(unit))
end

--- Checks whether the unit can hit with a melee attack the given target unit.
function Game:canHit(unit, target)
	return self:isInPositions(target, self:allowedHits(unit))
end

--- Checks whether the unit can shoot with a range attack the given target unit.
function Game:canShoot(unit, target)
	return self:isInPositions(target, self:allowedShots(unit))
end

--- Checks whether the given position is walkable.
function Game:isWalkable(x, y)
	return self:isInbounds(x, y) and tiles.KIND[self.map[y + 1][x + 1]].walkable
end

--- Checks whether there is no units on the position.
function Game:isEmpty(x, y)
	return not self:getUnitAt(x, y)
end

--- Checks whether a position is solid and blocks the line of sight.
function Game:isSolid(x, y)
	return not self:isInbounds(x, y) or tiles.KIND[self.map[y + 1][x + 1]].solid
end

--- Checks whether the unit has any pending actions in the current turn.
function Game:isPendingUnit(unit)
	if not unit:isAlive() then
		return false
	end

	if
		(unit:isEnemy() and self.state ~= game.STATE.ENEMY_TURN)
		or (unit:isPlayer() and self.state ~= game.STATE.PLAYER_TURN)
	then
		return false
	end

	return not (unit.hasMoved and unit.hasShot and unit.hasHit)
end

--- Gets the unit at the position. If there is no unit it returns nil.
function Game:getUnitAt(x, y)
	for _, unit in ipairs(self.playerUnits) do
		if unit:isAlive() and unit.x == x and unit.y == y then
			return unit
		end
	end
	for _, unit in ipairs(self.enemyUnits) do
		if unit:isAlive() and unit.x == x and unit.y == y then
			return unit
		end
	end
end

--- Checks whether the given point is in the bounds of the playable grid.
function Game:isInbounds(x, y)
	return util.isInRect(0, 0, conf.GRID_SIZE, conf.GRID_SIZE, x, y)
end

--- Checks whether the game as reached the victory condition.
function Game:isVictory()
	for _, unit in ipairs(self.enemyUnits) do
		if unit:isAlive() then
			return false
		end
	end
	return true
end

--- Checks whether the game has reached the game over condition.
function Game:isGameOver()
	for _, unit in ipairs(self.playerUnits) do
		if unit:isAlive() then
			return false
		end
	end
	return true
end

--- Returns the current aggregated game stats.
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
