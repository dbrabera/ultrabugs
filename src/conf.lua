local conf = {}

conf.GRID_SIZE = 10
conf.SPRITE_SIZE = 16
conf.SCREEN_WIDTH = 320
conf.SCREEN_HEIGHT = 180
conf.SCALE = 4

conf.WHITE = { 255, 255, 255 }
conf.BLACK = { 0, 0, 0 }
conf.LIME = { 153, 229, 80 }
conf.YELLOW = { 251, 242, 54 }
conf.RED = { 172, 50, 50 }
conf.GREY = { 105, 106, 106 }

function love.conf(t)
	t.window.title = "SpaceBugs"
	t.window.width = conf.SCREEN_WIDTH * conf.SCALE
	t.window.height = conf.SCREEN_HEIGHT * conf.SCALE
end

return conf
