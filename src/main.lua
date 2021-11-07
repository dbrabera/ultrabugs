local conf = require("conf")
local game = require("game")
local sprite = require("sprite")
local util = require("util")

local g = game.Game.new(40, -12)
local sprites = nil

function love.load()
	sprites = sprite.SpriteAtlas.new("assets/sprites.png")
end

function love.update(dt)
	g:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	g:keypressed(key)
end

function love.mousemoved(x, y, dx, dy, istouch)
	x, y = util.scaledCoords(x, y, conf.SCALE)
	g:mousemoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
	x, y = util.scaledCoords(x, y, conf.SCALE)
	g:mousepressed(x, y, button)
end

function love.draw()
	love.graphics.scale(conf.SCALE, conf.SCALE)
	g:draw(sprites)
end
