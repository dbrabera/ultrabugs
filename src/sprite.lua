SpriteAtlas = {}

function SpriteAtlas.new(path)
	local self = {}
	setmetatable(self, { __index = SpriteAtlas })

	love.graphics.setDefaultFilter("nearest")

	self.img = love.graphics.newImage(path)

	local width, height = self.img:getDimensions()
	self.quads = {}

	for j = 0, (height / SPRITE_SIZE) - 1 do
		for i = 0, (width / SPRITE_SIZE) - 1 do
			table.insert(
				self.quads,
				love.graphics.newQuad(i * SPRITE_SIZE, j * SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE, self.img)
			)
		end
	end

	return self
end

function SpriteAtlas:draw(id, x, y)
	love.graphics.draw(self.img, self.quads[id], x, y)
end
