local conf = require("conf")
local game = require("game")
local util = require("util")
local levels = require("levels")

local screens = {}

local MainScreen = {}

function screens.newMainScreen(engine)
	local self = {}
	setmetatable(self, { __index = MainScreen })

	self.engine = engine

	return self
end

function MainScreen:keypressed(key)
	if key == "space" then
		self.engine:push(screens.newGameScreen(self.engine))
	end
end

function MainScreen:draw()
	util.drawText("< Press space to start >", self.engine.bold, conf.WHITE, 80, 115)
end

local GameOverScreen = {}

function screens.newGameOverScreen(engine, level, turnCount, killCount)
	local self = {}
	setmetatable(self, { __index = GameOverScreen })

	self.engine = engine
	self.level = level
	self.turnCount = turnCount
	self.killCount = killCount

	return self
end

function GameOverScreen:keypressed(key)
	if key == "space" then
		self.engine:pop()
		self.engine:push(screens.newGameScreen(self.engine))
	end
end

function GameOverScreen:draw()
	util.drawText("Your squad has died", self.engine.bold, conf.WHITE, 95, 55)

	util.drawText("Level", self.engine.regular, conf.WHITE, 135, 75)
	util.drawText(self.level, self.engine.regular, conf.WHITE, 175, 75)

	util.drawText("Turns taken", self.engine.regular, conf.WHITE, 103, 85)
	util.drawText(self.turnCount, self.engine.regular, conf.WHITE, 175, 85)

	util.drawText("Bugs killed", self.engine.regular, conf.WHITE, 106, 95)
	util.drawText(self.killCount, self.engine.regular, conf.WHITE, 175, 95)

	util.drawText("< Press space to try again >", self.engine.bold, conf.WHITE, 70, 115)
end

local GameScreen = {}

function screens.newGameScreen(engine)
	local self = {}
	setmetatable(self, { __index = GameScreen })

	self.engine = engine
	self.lvl = 1
	self.turnCount = 0
	self.killCount = 0
	self.game = game.newGame(self.lvl, 80, 10)

	return self
end

function GameScreen:keypressed(key)
	self.game:keypressed(key)
end

function GameScreen:mousemoved(x, y)
	self.game:mousemoved(x, y)
end

function GameScreen:mousepressed(x, y, button)
	self.game:mousepressed(x, y, button)
end

function GameScreen:update(dt)
	self.game:update(dt)

	if self.game:isGameOver() or self.game:isVictory() then
		local stats = self.game:stats()
		self.turnCount = self.turnCount + stats.turnCount
		self.killCount = self.killCount + stats.killCount
	end

	if self.game:isGameOver() then
		self.engine:pop()
		self.engine:push(screens.newGameOverScreen(self.engine, self.lvl, self.turnCount, self.killCount))
	elseif self.game:isVictory() then
		if self.lvl == levels.MAX_LEVEL then
			self.engine:pop()
		else
			self.lvl = self.lvl + 1
			self.game = game.newGame(self.lvl, 80, 10, self.game.playerUnits)
		end
	end
end

local ICONS = {
	MOVE = { 45, 53, 61 },
	SHOOT = { 46, 54, 62 },
	FIGHT = { 47, 55, 63 },
}

local function icon(action, selectedAction, disabled)
	local idx = 3
	if disabled then
		idx = 1
	elseif action == selectedAction then
		idx = 2
	end

	if action == game.ACTION.MOVE then
		return ICONS.MOVE[idx]
	elseif action == game.ACTION.SHOOT then
		return ICONS.SHOOT[idx]
	elseif action == game.ACTION.FIGHT then
		return ICONS.FIGHT[idx]
	end
end

function GameScreen:draw()
	local hoveredUnit = self.game:getUnitAt(self.game.cursorGameX, self.game.cursorGameY)
	local padding = 8

	for i, unit in ipairs(self.game.playerUnits) do
		local x, y = padding, (conf.SPRITE_SIZE * (i - 1) + 4 * i) + padding
		self.engine.sprites:draw(unit.kind.spriteID, x, y, unit:isAlive() and 1 or 0.3)

		local color = self.game.selectedUnit == unit and conf.WHITE or conf.GREY
		util.drawRectangle("line", x, y, conf.SPRITE_SIZE, conf.SPRITE_SIZE, color)

		game.drawHealthbar(x + 18, y + 8, unit.health, unit.kind.maxHealth, false, color)
	end

	if hoveredUnit and hoveredUnit.kind.isEnemy then
		local x, y = 250, 150

		self.engine.sprites:draw(hoveredUnit.kind.spriteID, x, y)
		util.drawRectangle("line", x, y, conf.SPRITE_SIZE, conf.SPRITE_SIZE, conf.GREY)
		game.drawHealthbar(x + 18, y + 8, hoveredUnit.health, hoveredUnit.kind.maxHealth, false, conf.GREY)
		util.drawText(hoveredUnit.kind.name, self.engine.regular, conf.GREY, x + 18, y + 8)
	end

	self.game:draw(self.engine.sprites)

	if self.game.selectedUnit then
		local unit = self.game.selectedUnit

		self.engine.sprites:draw(unit.kind.spriteID, padding, 130)
		util.drawRectangle("line", padding, 130, conf.SPRITE_SIZE, conf.SPRITE_SIZE, conf.WHITE)
		game.drawHealthbar(padding + 18, 130 + 8, unit.health, unit.kind.maxHealth, false, conf.WHITE)
		util.drawText(unit.kind.name, self.engine.regular, conf.WHITE, padding + 18, 130 + 8)

		self.engine.sprites:draw(icon(game.ACTION.MOVE, self.game.action, unit.hasMoved), padding, 150)
		self.engine.sprites:draw(
			icon(game.ACTION.SHOOT, self.game.action, unit.hasShot),
			padding + conf.SPRITE_SIZE,
			150
		)
		self.engine.sprites:draw(
			icon(game.ACTION.FIGHT, self.game.action, unit.hasHit),
			padding + conf.SPRITE_SIZE * 2,
			150
		)
	end

	util.drawText("Level " .. self.lvl, self.engine.regular, conf.WHITE, 260, 10)
	love.graphics.draw(self.engine.minimap, 270, 24)
	util.drawRectangle("fill", 270, 24 + (10 * self.lvl), conf.SPRITE_SIZE, 100, conf.BLACK, 0.5)
end

return screens
