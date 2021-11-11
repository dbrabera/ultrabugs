local screens = require("screens")
local sprite = require("sprite")

local engine = {}

local Engine = {}

function engine.newEngine()
	local self = {}
	setmetatable(self, { __index = Engine })

	self.screens = { screens.newMainScreen(self) }

	return self
end

function Engine:load()
	self.sprites = sprite.newSpriteAtlas("assets/sprites.png")
	self.regular = love.graphics.newFont("assets/GravityRegular5.ttf", 5)
	self.bold = love.graphics.newFont("assets/GravityBold8.ttf", 8)
end

function Engine:push(screen)
	table.insert(self.screens, screen)
end

function Engine:peek()
	return self.screens[#self.screens]
end

function Engine:pop()
	if #self.screens == 1 then
		return nil
	end
	return table.remove(self.screens)
end

function Engine:update(dt)
	local screen = self:peek()
	if screen.update then
		screen:update(dt)
	end
end

function Engine:draw()
	local screen = self:peek()
	if screen.draw then
		screen:draw()
	end
end

function Engine:keypressed(key)
	local screen = self:peek()
	if screen.keypressed then
		screen:keypressed(key)
	end
end

function Engine:mousemoved(x, y)
	local screen = self:peek()
	if screen.mousemoved then
		screen:mousemoved(x, y)
	end
end

function Engine:mousepressed(x, y, button)
	local screen = self:peek()
	if screen.mousepressed then
		screen:mousepressed(x, y, button)
	end
end

return engine
