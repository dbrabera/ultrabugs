local conf = require("conf")
local game = require("game")
local util = require("util")

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
	self.game = game.newGame(80, 10)

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
		self.engine:pop()
	end
end

local function phaseColor(phase)
	if phase == game.PHASE.MOVEMENT then
		return conf.LIME
	elseif phase == game.PHASE.SHOOTING then
		return conf.YELLOW
	elseif phase == game.PHASE.COMBAT then
		return conf.RED
	end
end

function GameScreen:draw()
	if self.game.phase == game.PHASE.MOVEMENT then
		util.drawText("MOVEMENT", self.engine.regular, conf.WHITE, 255, 8)
	elseif self.game.phase == game.PHASE.SHOOTING then
		util.drawText("SHOOTING", self.engine.regular, conf.WHITE, 255, 8)
	elseif self.game.phase == game.PHASE.COMBAT then
		util.drawText("COMBAT", self.engine.regular, conf.WHITE, 260, 8)
	end

	util.drawText("PHASE", self.engine.regular, conf.WHITE, 264, 16)
	util.drawRectangle("line", 250, 4, 52, 21, phaseColor(self.game.phase))

	local hoveredUnit = self.game:getUnitAt(self.game.cursorGameX, self.game.cursorGameY)

	for i, unit in ipairs(self.game.playerUnits) do
		local x, y = 4, 16 * (i - 1) + 4 * i
		self.engine.sprites:draw(unit.kind.spriteID, x, y, unit:isAlive() and 1 or 0.3)

		local color = self.game.selectedUnit == unit and conf.WHITE or conf.GREY
		util.drawRectangle("line", x, y, 16, 16, color)

		game.drawHealthbar(x + 18, y + 8, unit.health, unit.kind.maxHealth, false, color)
	end

	if hoveredUnit and hoveredUnit.kind.isEnemy then
		local x, y = 4, 150

		self.engine.sprites:draw(hoveredUnit.kind.spriteID, x, y)
		util.drawRectangle("line", x, y, 16, 16, conf.GREY)
		game.drawHealthbar(x + 18, y + 8, hoveredUnit.health, hoveredUnit.kind.maxHealth, false, conf.GREY)
		util.drawText(hoveredUnit.kind.name, self.engine.regular, conf.GREY, x + 18, y + 8)
	end

	self.game:draw(self.engine.sprites)
end

return screens
