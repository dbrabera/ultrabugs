local sprite = {}

--- A sprite atlas maps an image containing multiple sprites to individual sprites referenced by an ID.
local SpriteAtlas = {}

--- Creates a new sprite atlas from the image found at the given path.
function sprite.newSpriteAtlas(path, size)
	local self = {}
	setmetatable(self, { __index = SpriteAtlas })

	love.graphics.setDefaultFilter("nearest")

	self.img = love.graphics.newImage(path)
	self.size = size

	local width, height = self.img:getDimensions()
	self.quads = {}

	for j = 0, (height / size) - 1 do
		for i = 0, (width / size) - 1 do
			table.insert(self.quads, love.graphics.newQuad(i * size, j * size, size, size, self.img))
		end
	end

	return self
end

--- Draws the sprite associated with the ID in the given screen position.
function SpriteAtlas:draw(id, x, y, alpha)
	love.graphics.setColor(1, 1, 1, alpha or 1)
	love.graphics.draw(self.img, self.quads[id], x, y)
end

--- Returns the image data associated with the given ID.
function SpriteAtlas:imageData(id, scale)
	local canvas = love.graphics.getCanvas()
	local tmp = love.graphics.newCanvas(self.size * scale, self.size * scale)
	love.graphics.setCanvas(tmp)

	love.graphics.scale(scale, scale)
	love.graphics.draw(self.img, self.quads[id], 0, 0)

	love.graphics.setCanvas(canvas)
	return tmp:newImageData()
end

return sprite
