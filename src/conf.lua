local conf = {}

conf.GRID_SIZE = 10
conf.SPRITE_SIZE = 16
conf.SCALE = 4

function love.conf(t)
	t.window.width = 240 * conf.SCALE
	t.window.height = 136 * conf.SCALE
end

return conf
