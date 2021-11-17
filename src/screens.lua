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
	util.drawText("Press space to start", self.engine.bold, conf.WHITE, 90, 100)
end

local GameScreen = {}

function screens.newGameScreen(engine)
	local self = {}
	setmetatable(self, { __index = GameScreen })

	self.engine = engine
	self.lvl = 1
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

	if self.game:isGameOver() then
		self.engine:pop()
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

	for i, unit in ipairs(self.game.playerUnits) do
		local x, y = 4, 16 * (i - 1) + 4 * i
		self.engine.sprites:draw(unit.kind.spriteID, x, y, unit:isAlive() and 1 or 0.3)

		local color = self.game.selectedUnit == unit and conf.WHITE or conf.GREY
		util.drawRectangle("line", x, y, 16, 16, color)

		game.drawHealthbar(x + 18, y + 8, unit.health, unit.kind.maxHealth, false, color)
	end

	if hoveredUnit and hoveredUnit.kind.isEnemy then
		local x, y = 250, 150

		self.engine.sprites:draw(hoveredUnit.kind.spriteID, x, y)
		util.drawRectangle("line", x, y, 16, 16, conf.GREY)
		game.drawHealthbar(x + 18, y + 8, hoveredUnit.health, hoveredUnit.kind.maxHealth, false, conf.GREY)
		util.drawText(hoveredUnit.kind.name, self.engine.regular, conf.GREY, x + 18, y + 8)
	end

	self.game:draw(self.engine.sprites)

	if self.game.selectedUnit then
		local unit = self.game.selectedUnit

		self.engine.sprites:draw(unit.kind.spriteID, 4, 130)
		util.drawRectangle("line", 4, 130, 16, 16, conf.WHITE)
		game.drawHealthbar(4 + 18, 130 + 8, unit.health, unit.kind.maxHealth, false, conf.WHITE)
		util.drawText(unit.kind.name, self.engine.regular, conf.WHITE, 4 + 18, 130 + 8)

		self.engine.sprites:draw(icon(game.ACTION.MOVE, self.game.action, unit.hasMoved), 4, 150)
		self.engine.sprites:draw(icon(game.ACTION.SHOOT, self.game.action, unit.hasShot), 20, 150)
		self.engine.sprites:draw(icon(game.ACTION.FIGHT, self.game.action, unit.hasHit), 36, 150)
	end
end

return screens
