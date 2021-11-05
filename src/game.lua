require("conf")

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

local ACTION = {
	MOVE = "move",
	HIT = "hit",
	FIRE = "fire",
}

local Hero = {}

function Hero.new(game_x, game_y)
	local self = {}
	setmetatable(self, { __index = Hero })

	self.game_x = game_x
	self.game_y = game_y
	self.meleeDamage = 1
	self.rangedDamage = 2

	return self
end

function Hero:move(game_x, game_y)
	self.game_x = game_x
	self.game_y = game_y
end

function Hero:hit(actor)
	actor:takeDamage(self.meleeDamage)
end

function Hero:fire(actor)
	actor:takeDamage(self.rangedDamage)
end

local Bug = {}

function Bug.new(game_x, game_y)
	local self = {}
	setmetatable(self, { __index = Bug })

	self.game_x = game_x
	self.game_y = game_y
	self.health = 2

	return self
end

function Bug:takeDamage(damage)
	if self.health <= damage then
		self.health = 0
	else
		self.health = self.health - damage
	end
end

function Bug:isAlive()
	return self.health > 0
end

Game = {}

function Game.new(screen_x, screen_y)
	local self = {}
	setmetatable(self, { __index = Game })

	self.screen_x = screen_x
	self.screen_y = screen_y
	self.hero = Hero.new(2, 2)
	self.bugs = {
		Bug.new(2, 4),
		Bug.new(7, 7),
	}
	self.pointer_game_x = -1
	self.pointer_game_y = -1
	self.action = ACTION.MOVE

	return self
end

function Game:keypressed(key)
	if key == "1" then
		self.action = ACTION.MOVE
	elseif key == "2" then
		self.action = ACTION.HIT
	elseif key == "3" then
		self.action = ACTION.FIRE
	end
end

function Game:mousepressed(x, y, button)
	if button ~= 1 then
		return
	end

	local gameX, gameY = self:game_coords(x, y)

	if self.action == ACTION.MOVE then
		if self:canMove(self.hero, gameX, gameY) then
			self.hero:move(gameX, gameY)
		end

		return
	end

	local target = self:getActorAt(gameX, gameY)

	if not target then
		return
	end

	if self.action == ACTION.HIT then
		if self:canHit(self.hero, target) then
			self.hero:hit(target)
		end
	elseif self.action == ACTION.FIRE then
		if self:canFire(self.hero, target) then
			self.hero:fire(target)
		end
	end
end

function Game:mousemoved(x, y)
	self.pointer_game_x, self.pointer_game_y = self:game_coords(x, y)
end

function Game:update(dt) end

function Game:isGameOver()
	for _, bug in ipairs(self.bugs) do
		if bug:isAlive() then
			return false
		end
	end
	return true
end

function Game:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.print({ { 255, 255, 255 }, self.action }, 0, 0)

	for i = 0, GRID_SIZE - 1 do
		for j = 0, GRID_SIZE - 1 do
			local tile = TILES[map[j + 1][i + 1]]
			sprites:draw(tile.spriteID, self.screen_x + i * SPRITE_SIZE, self.screen_y + j * SPRITE_SIZE)
		end
	end

	for _, pos in ipairs(self:allowedActions(self.hero)) do
		local x, y = self:screen_coords(pos.x, pos.y)
		sprites:draw(17, x, y, 11)
	end

	if self:is_inbounds(self.pointer_game_x, self.pointer_game_y) then
		x, y = self:screen_coords(self.pointer_game_x, self.pointer_game_y)
		love.graphics.setColor(255, 255, 255)
		love.graphics.rectangle("line", x, y, 16, 16)
	end

	local x, y = self:screen_coords(self.hero.game_x, self.hero.game_y)
	sprites:draw(9, x, y, 11)

	for _, bug in ipairs(self.bugs) do
		if bug:isAlive() then
			x, y = self:screen_coords(bug.game_x, bug.game_y)
			sprites:draw(25, x, y, 11)
		end
	end
end

function Game:allowedActions(actor)
	if self.action == ACTION.MOVE then
		return self:allowedMoves(actor)
	elseif self.action == ACTION.HIT then
		return self:allowedHits(actor)
	elseif self.action == ACTION.FIRE then
		return self:allowedFires(actor)
	end
end

function Game:allowedMoves(actor)
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

		if self:isWalkable(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:allowedHits(actor)
	local res = {}

	for _, pos in ipairs({
		{ -1, 0 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
	}) do
		local x, y = actor.game_x + pos[1], actor.game_y + pos[2]

		if self:isWalkable(x, y) or self:getActorAt(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:allowedFires(actor)
	local res = {}

	for _, pos in ipairs({
		{ -2, 0 },
		{ 0, -2 },
		{ 0, 2 },
		{ 2, 0 },
		{ -3, 0 },
		{ 0, -3 },
		{ 0, 3 },
		{ 3, 0 },
	}) do
		local x, y = actor.game_x + pos[1], actor.game_y + pos[2]

		if self:isWalkable(x, y) or self:getActorAt(x, y) then
			table.insert(res, { x = x, y = y })
		end
	end

	return res
end

function Game:isAllowed(source, target, positions)
	for _, pos in ipairs(positions) do
		if target.game_x == pos.x and target.game_y == pos.y then
			return true
		end
	end
	return false
end

function Game:canMove(actor, x, y)
	return self:isAllowed(actor, { game_x = x, game_y = y }, self:allowedMoves(actor))
end

function Game:canHit(actor, target)
	return self:isAllowed(actor, target, self:allowedHits(actor))
end

function Game:canFire(actor, target)
	return self:isAllowed(actor, target, self:allowedFires(actor))
end

function Game:isWalkable(gameX, gameY)
	if self:getActorAt(gameX, gameY) then
		return false
	end
	return self:is_inbounds(gameX, gameY) and TILES[map[gameY + 1][gameX + 1]].walkable
end

function Game:getActorAt(gameX, gameY)
	for _, bug in ipairs(self.bugs) do
		if bug:isAlive() and bug.game_x == gameX and bug.game_y == gameY then
			return bug
		end
	end
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
