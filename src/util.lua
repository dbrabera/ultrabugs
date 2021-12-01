local conf = require("conf")

local util = {}

--- Returns the transformed coordinates according to the given scale.
function util.scaledCoords(x, y, scale)
	return math.floor(x / scale), math.floor(y / scale)
end

--- A FIFO queue.
local Queue = {}

--- Creates a new FIFO queue.
-- From: https://www.lua.org/pil/11.4.html
function util.newQueue(elems)
	local self = {}
	setmetatable(self, { __index = Queue })

	self.first = 1
	self.last = 0

	self.elems = {}
	for i, elem in ipairs(elems) do
		self.elems[i] = elem
		self.last = i
	end

	return self
end

--- Returns the number of elements in the queue.
function Queue:len()
	if self.first > self.last then
		return 0
	end
	return (self.last - self.first) + 1
end

--- Puts an element at the end of the queue.
function Queue:put(elem)
	local last = self.last + 1
	self.elems[last] = elem
	self.last = last
end

--- Gets the first element in the queue. If there is no elements it returns nil.
function Queue:get()
	if self.first > self.last then
		return nil
	end

	local elem = self.elems[self.first]
	self.elems[self.first] = nil

	self.first = self.first + 1
	return elem
end

--- Returns the neighbors of a position in a grid.
function util.neighbors(pos)
	local res = {}

	for _, delta in ipairs({
		{ -1, 0 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
	}) do
		table.insert(res, { x = pos.x + delta[1], y = pos.y + delta[2] })
	end

	return res
end

--- Finds the shortest path from the source to the destination in a grid.
-- It uses BFS as the grid is small (8x8) and unweighted and it is simpler
-- to implement than A*.
--
-- From: https://www.redblobgames.com/pathfinding/a-star/introduction.html
function util.findPath(src, dst, isWalkable)
	local frontier = util.newQueue({ src })
	local cameFrom = {}

	while frontier:len() > 0 do
		local curr = frontier:get()

		if curr.x == dst.x and curr.y == dst.y then
			break
		end

		for _, next in ipairs(util.neighbors({ x = curr.x, y = curr.y })) do
			local id = next.x .. "|" .. next.y

			if isWalkable(next) or (next.x == dst.x and next.y == dst.y) then
				if not cameFrom[id] then
					frontier:put(next)
					cameFrom[id] = curr
				end
			end
		end
	end

	local path = {}
	local curr = dst

	while curr ~= src do
		local id = curr.x .. "|" .. curr.y
		table.insert(path, curr)
		curr = cameFrom[id]
		if not curr then
			-- no path found
			return nil
		end
	end

	return path
end

-- Returns the straight Line of Sight between the source and the destination.
function util.los(src, dst, isSolid)
	if src.x ~= dst.x and src.y ~= dst.y then
		return {}
	end

	local dx, dy = util.sign(dst.x - src.x), util.sign(dst.y - src.y)
	local curr, res = src, {}

	while not (curr.x == dst.x and curr.y == dst.y) do
		local next = { x = curr.x + dx, y = curr.y + dy }
		if isSolid(next) then
			return res
		end

		curr = next
		table.insert(res, curr)
	end
	return res
end

-- Sign returns a +/- 1 depending on the sign of n. If n is zero it returns zero.
function util.sign(n)
	if n == 0 then
		return 0
	end
	return n > 0 and 1 or -1
end

--- Enumerates the different text alignments.
util.ALING = {
	LEFT = "left",
	CENTER = "center",
	RIGHT = "right",
}

--- Draws the text using the given font, color and an optional alignment.
function util.drawText(text, font, color, x, y, align)
	if not align then
		align = util.ALING.LEFT
	end

	local width = font:getWidth(text)

	if align == util.ALING.CENTER then
		x = x - (width / 2)
	elseif align == util.ALING.RIGHT then
		x = x - width
	end

	love.graphics.setFont(font)
	love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255)
	love.graphics.print(text, x, y)
end

--- Draws a rectangle with the given color and an optional alpha transparency.
function util.drawRectangle(mode, x, y, w, h, color, alpha)
	if not alpha then
		alpha = 1
	end

	love.graphics.setColor(color[1] / 255, color[2] / 255, color[3] / 255, alpha)
	love.graphics.rectangle(mode, x, y, w, h)
end

--- Returns the center of the screen.
function util.screenCenter()
	return conf.SCREEN_WIDTH / 2, conf.SCREEN_HEIGHT / 2
end

--- Checks whether the coordinates x2, y2 are inside the rectange formed by the given rectangle
-- described by its origin x1, y1 and its width and height.
function util.isInRect(x1, y1, w, h, x2, y2)
	return x1 <= x2 and x2 < x1 + w and y1 <= y2 and y2 < y1 + h
end

--- Flashes two colors over time according to the current age in seconds.
function util.flash(age, a, b)
	if math.floor(age * 2 % 2) == 0 then
		return a
	end
	return b
end

return util
