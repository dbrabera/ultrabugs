local conf = require("conf")
local engine = require("engine")
local util = require("util")

local eng = engine.newEngine()

function love.load()
	eng:load()
end

function love.update(dt)
	eng:update(dt)
end

function love.keypressed(key)
	eng:keypressed(key)
end

function love.mousemoved(x, y)
	x, y = util.scaledCoords(x, y, conf.SCALE)
	eng:mousemoved(x, y)
end

function love.mousepressed(x, y, button)
	x, y = util.scaledCoords(x, y, conf.SCALE)
	eng:mousepressed(x, y, button)
end

function love.draw()
	love.graphics.scale(conf.SCALE, conf.SCALE)
	eng:draw()
end
