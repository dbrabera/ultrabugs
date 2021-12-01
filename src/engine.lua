local conf = require("conf")
local screens = require("screens")
local sprite = require("sprite")

local engine = {}

--- The engine handles all the callbacks from the Love2D library. It loads and keeps
-- track of all the game assets and has a stack of screens to which it routes the callbacks.
-- This allows the game to easily switch between screens without using any global state.
local Engine = {}

--- Creates a new engine.
function engine.newEngine()
	local self = {}
	setmetatable(self, { __index = Engine })

	self.screens = { screens.newMainScreen(self) }

	return self
end

--- Handles the load callback.
function Engine:load()
	self.sprites = sprite.newSpriteAtlas("assets/sprites.png", conf.SPRITE_SIZE)

	love.graphics.setDefaultFilter("nearest")

	self.minimap = love.graphics.newImage("assets/minimap.png")
	self.titleBg = love.graphics.newImage("assets/title.png")
	self.missionBg = love.graphics.newImage("assets/mission.png")
	self.spaceBg = love.graphics.newImage("assets/space.png")

	self.regular = love.graphics.newFont("assets/GravityRegular5.ttf", 5)
	self.bold = love.graphics.newFont("assets/GravityBold8.ttf", 8)

	love.mouse.setCursor(self.cursor)
end

--- Pushes the screen into the screen stack.
function Engine:push(screen)
	table.insert(self.screens, screen)
end

--- Returns the screen at the top of the screen stack.
function Engine:peek()
	return self.screens[#self.screens]
end

--- Removes and returns the screen at the top of the screen stack.
function Engine:pop()
	if #self.screens == 1 then
		return nil
	end
	return table.remove(self.screens)
end

--- Handles the update callback.
function Engine:update(dt)
	local screen = self:peek()
	if screen.update then
		screen:update(dt)
	end
end

--- Handles the draw callback.
function Engine:draw()
	local screen = self:peek()
	if screen.draw then
		screen:draw()
	end
end

--- Handles the keypressed callback.
function Engine:keypressed(key)
	local screen = self:peek()
	if screen.keypressed then
		screen:keypressed(key)
	end
end

--- Handles the mousemoved callback.
function Engine:mousemoved(x, y)
	local screen = self:peek()
	if screen.mousemoved then
		screen:mousemoved(x, y)
	end
end

--- Handles the mousepressed callback.
function Engine:mousepressed(x, y, button)
	local screen = self:peek()
	if screen.mousepressed then
		screen:mousepressed(x, y, button)
	end
end

return engine
