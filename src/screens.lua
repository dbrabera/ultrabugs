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
	util.drawText("Press space to start", conf.WHITE, 0, 0)
end

local GameScreen = {}

function screens.newGameScreen(engine)
	local self = {}
	setmetatable(self, { __index = GameScreen })

	self.engine = engine
	self.game = game.newGame(40, -12)

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

function GameScreen:draw()
	self.game:draw(self.engine.sprites)
end

return screens
