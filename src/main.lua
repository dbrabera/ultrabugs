require("conf")
require("game")
require("sprite")

local game = Game.new(40, -12)

function love.load()
	sprites = SpriteAtlas.new("assets/sprites.png")
end

function love.update(dt)
	game:update(dt)
end

function love.draw()
	love.graphics.scale(SCALE, SCALE)
	game:draw()
end
