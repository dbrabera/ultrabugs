local GRID_SIZE = 10
local SPRITE_SIZE = 16
local SCALE = 4

function tile(name, spriteID, walkable)
	return {
		name = name,
		spriteID = spriteID,
		walkable = walkable,
	}
end

local TILES = {
	tile("ground", 1, true),
	tile("wall", 2, false),
	tile("wall", 3, false),
	tile("wall", 4, false),
}

local map = {
	{ 3, 2, 2, 2, 2, 2, 2, 2, 2, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 2, 2, 2, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 1, 1, 1, 1, 1, 1, 1, 1, 4 },
	{ 3, 2, 2, 2, 2, 2, 2, 2, 2, 4 },
}

local Hero = {}

function Hero.new(game_x, game_y)
	local self = {}
	setmetatable(self, { __index = Hero })

	self.game_x = game_x
	self.game_y = game_y

	return self
end

function Hero:move(game_x, game_y)
	self.game_x = game_x
	self.game_y = game_y
end

local Game = {}

function Game.new(screen_x, screen_y)
	local self = {}
	setmetatable(self, { __index = Game })

	self.screen_x = screen_x
	self.screen_y = screen_y
	self.hero = Hero.new(1, 1)
	self.pointer_game_x = -1
	self.pointer_game_y = -1

	return self
end

function Game:update(dt)
	local mx, my = love.mouse.getPosition()
	local md = love.mouse.isDown(1)

	mx = math.floor(mx / SCALE)
	my = math.floor(my / SCALE)

	self.pointer_game_x, self.pointer_game_y = self:game_coords(mx, my)

	if md and self:is_walkable(self.pointer_game_x, self.pointer_game_y) then
		self.hero:move(self.pointer_game_x, self.pointer_game_y)
	end
end

function Game:draw()
	for i = 0, GRID_SIZE - 1 do
		for j = 0, GRID_SIZE - 1 do
			local tile = TILES[map[j + 1][i + 1]]
			drawSprite(tile.spriteID, self.screen_x + i * SPRITE_SIZE, self.screen_y + j * SPRITE_SIZE)
		end
	end

	for _, pos in ipairs(self:allowed_moves(self.hero)) do
		local x, y = self:screen_coords(pos.x, pos.y)
		drawSprite(17, x, y, 11)
	end

	if self:is_inbounds(self.pointer_game_x, self.pointer_game_y) then
		x, y = self:screen_coords(self.pointer_game_x, self.pointer_game_y)
		love.graphics.setColor(255, 255, 255)
		love.graphics.rectangle("line", x, y, 16, 16)
	end

	local x, y = self:screen_coords(self.hero.game_x, self.hero.game_y)
	drawSprite(9, x, y, 11)
end

function Game:allowed_moves(actor)
	local res = {}

	for _, pos in ipairs({
		{ -1, 0 },
		{ -1, -1 },
		{ -1, 1 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
		{ 1, -1 },
		{ 1, 1 },
	}) do
		local x, y = actor.game_x + pos[1], actor.game_y + pos[2]

		if self:is_walkable(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:is_walkable(game_x, game_y)
	return self:is_inbounds(game_x, game_y) and TILES[map[game_y + 1][game_x + 1]].walkable
end

function Game:is_inbounds(game_x, game_y)
	return game_x >= 0 and game_y >= 0 and game_x < GRID_SIZE and game_y < GRID_SIZE
end

function Game:screen_coords(game_x, game_y)
	return self.screen_x + game_x * SPRITE_SIZE, self.screen_y + game_y * SPRITE_SIZE
end

function Game:game_coords(screen_x, screen_y)
	local game_x = math.floor((screen_x - self.screen_x) / (SPRITE_SIZE + 1))
	local game_y = math.floor((screen_y - self.screen_y) / (SPRITE_SIZE + 1))
	return game_x, game_y
end

local game = Game.new(40, -12)

function love.load()
	sprites = loadSprites("assets/sprites.png")
end

function love.update(dt)
	game:update(dt)
end

function love.draw()
	love.graphics.scale(SCALE, SCALE)
	game:draw()
end

function loadSprites(path)
	love.graphics.setDefaultFilter("nearest")

	local img = love.graphics.newImage(path)

	local width, height = img:getDimensions()
	local quads = {}

	for j = 0, (height / SPRITE_SIZE) - 1 do
		for i = 0, (width / SPRITE_SIZE) - 1 do
			table.insert(quads, love.graphics.newQuad(i * SPRITE_SIZE, j * SPRITE_SIZE, SPRITE_SIZE, SPRITE_SIZE, img))
		end
	end

	return {
		img = img,
		quads = quads,
	}
end

function drawSprite(spriteID, x, y)
	love.graphics.draw(sprites.img, sprites.quads[spriteID], x, y)
end
