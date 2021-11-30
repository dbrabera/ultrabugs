local conf = {}

--- Size of the grid in tiles
conf.GRID_SIZE = 10
--- Size of the sprites in pixels
conf.SPRITE_SIZE = 16
--- Width of the screen
conf.SCREEN_WIDTH = 320
--- Height of the screen
conf.SCREEN_HEIGHT = 180
--- Scale to zoom in the screen
conf.SCALE = 3
--- Duration of the animations in seconds.
conf.ANIMATION_DURATION_SECONDS = 0.5

conf.BLACK = { 0, 0, 0 }
conf.DARK_GREY = { 34, 32, 52 }
conf.GREY = { 105, 106, 106 }
conf.BLUE = { 99, 155, 255 }
conf.LIGHT_BLUE = { 203, 219, 252 }
conf.LIME = { 153, 229, 80 }
conf.RED = { 172, 50, 50 }
conf.WHITE = { 255, 255, 255 }
conf.YELLOW = { 251, 242, 54 }

function love.conf(t)
	t.window.title = "UltraBugs"
	t.window.width = conf.SCREEN_WIDTH * conf.SCALE
	t.window.height = conf.SCREEN_HEIGHT * conf.SCALE
end

return conf
