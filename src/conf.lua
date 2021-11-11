local conf = {}

conf.GRID_SIZE = 10
conf.SPRITE_SIZE = 16
conf.SCALE = 4

conf.WHITE = { 255, 255, 255 }
conf.BLACK = { 0, 0, 0 }
conf.LIME = { 153, 229, 80 }
conf.YELLOW = { 251, 242, 54 }
conf.RED = { 172, 50, 50 }
conf.GREY = { 105, 106, 106 }

function love.conf(t)
	t.window.width = 320 * conf.SCALE
	t.window.height = 180 * conf.SCALE
end

return conf
