local conf = require("conf")

local sprite = {}

local SpriteAtlas = {}

function sprite.newSpriteAtlas(path)
	local self = {}
	setmetatable(self, { __index = SpriteAtlas })

	love.graphics.setDefaultFilter("nearest")

	self.img = love.graphics.newImage(path)

	local width, height = self.img:getDimensions()
	self.quads = {}

	for j = 0, (height / conf.SPRITE_SIZE) - 1 do
		for i = 0, (width / conf.SPRITE_SIZE) - 1 do
			table.insert(
				self.quads,
				love.graphics.newQuad(
					i * conf.SPRITE_SIZE,
					j * conf.SPRITE_SIZE,
					conf.SPRITE_SIZE,
					conf.SPRITE_SIZE,
					self.img
				)
			)
		end
	end

	return self
end

function SpriteAtlas:draw(id, x, y, alpha)
	love.graphics.setColor(1, 1, 1, alpha or 1)
	love.graphics.draw(self.img, self.quads[id], x, y)
end

return sprite
