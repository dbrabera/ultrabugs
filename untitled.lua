-- title:  untitled
-- author: Diego Barbera
-- desc:   short description
-- script: lua

local GRID_SIZE = 10
local SPRITE_SIZE = 16

function tile(name, sprite, walkable)
	return {
		name = name,
		sprite = sprite,
		walkable = walkable,
	}
end

local TILES = {
	tile("ground", 2, true),
	tile("wall", 4, false),
	tile("wall", 6, false),
	tile("wall", 8, false),
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

function Game:update()
	local mx, my, md = mouse()

	self.pointer_game_x, self.pointer_game_y = self:game_coords(mx, my)

	if md and self:is_walkable(self.pointer_game_x, self.pointer_game_y) then
		self.hero:move(self.pointer_game_x, self.pointer_game_y)
	end
end

function Game:draw()
	for i = 0, GRID_SIZE - 1 do
		for j = 0, GRID_SIZE - 1 do
			local tile = TILES[map[j + 1][i + 1]]
			sprite(tile.sprite, self.screen_x + i * SPRITE_SIZE, self.screen_y + j * SPRITE_SIZE)
		end
	end

	local x, y = self:screen_coords(self.hero.game_x, self.hero.game_y)
	sprite(256, x, y, 11)

	for _, pos in ipairs(self:allowed_moves(self.hero)) do
		local x, y = self:screen_coords(pos.x, pos.y)
		sprite(32, x, y, 11)
	end

	if self:is_inbounds(self.pointer_game_x, self.pointer_game_y) then
		x, y = self:screen_coords(self.pointer_game_x, self.pointer_game_y)
		rectb(x - 1, y - 1, 18, 18, 12)
	end
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

local game = Game.new(50, -12)

function TIC()
	cls(0)
	game:update()
	game:draw()
end

function sprite(id, x, y, alpha)
	alpha = alpha or -1

	spr(id, x, y, alpha)
	spr(id + 1, x + 8, y, alpha)
	spr(id + 16, x, y + 8, alpha)
	spr(id + 16 + 1, x + 8, y + 8, alpha)
end

-- <TILES>
-- 002:1111111111111111111111111111111111111111111111111111111111111111
-- 003:1111111011111110111111101111111011111110111111101111111011111110
-- 004:3333333333333333333333333333333333333333ccccccccffffffffffffffff
-- 005:3333333233333332333333323333333233333332ccccccccfffffffefffffffe
-- 007:0003333200033332000333320003333200033332000333320003333200033332
-- 008:2333300023333000233330002333300023333000233330002333300023333000
-- 018:1111111111111111111111111111111111111111111111111111111100000000
-- 019:1111111011111110111111101111111011111110111111101111111000000000
-- 020:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:fffffffefffffffefffffffefffffffefffffffefffffffefffffffefffffffe
-- 023:0003333200033332000333320003333200033332000333320003333200033332
-- 024:2333300023333000233330002333300023333000233330002333300023333000
-- 032:bbbbbbbbababababbbbbbbbbababababbbbbbbbbababababbbbbbbbbabababab
-- 033:bbbbbbbbababababbbbbbbbbababababbbbbbbbbababababbbbbbbbbabababab
-- 048:bbbbbbbbababababbbbbbbbbababababbbbbbbbbababababbbbbbbbbabababab
-- 049:bbbbbbbbababababbbbbbbbbababababbbbbbbbbababababbbbbbbbbabababab
-- </TILES>

-- <SPRITES>
-- 000:bbbbbb00bbbbb099bb000999b099f9cc0899f9cc0889f99a0888ff99b0888fff
-- 001:00bbbbbb990bbbbb999000bbcc9f990bcc9f9980a99f988099ff8880fff8880b
-- 016:b0ee00000dee0ddd0d0ff0ee0d0ff000b0b0eee0bbb0880bbbb0880bbbbb00bb
-- 017:00000000ddddddddeededee00000000b0eee0bbbb0880bbbb0880bbbbb00bbbb
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <FLAGS>
-- 000:10100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
