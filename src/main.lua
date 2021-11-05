require("conf")
require("game")
require("sprite")
require("util")

local game = Game.new(40, -12)

function love.load()
	sprites = SpriteAtlas.new("assets/sprites.png")
end

function love.update(dt)
	game:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	game:keypressed(key)
end

function love.mousemoved(x, y, dx, dy, istouch)
	x, y = scaledCoords(x, y, SCALE)
	game:mousemoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
	x, y = scaledCoords(x, y, SCALE)
	game:mousepressed(x, y, button)
end

function love.draw()
	love.graphics.scale(SCALE, SCALE)
	game:draw()
end
