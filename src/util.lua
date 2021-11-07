local util = {}

--- Returns the transformed coordinates according to the given scale.
function util.scaledCoords(x, y, scale)
	return math.floor(x / scale), math.floor(y / scale)
end

local Queue = {}

--- Creates a new FIFO queue.
-- From: https://www.lua.org/pil/11.4.html
function Queue.new(elems)
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
		{ -1, -1 },
		{ -1, 1 },
		{ 0, -1 },
		{ 0, 1 },
		{ 1, 0 },
		{ 1, -1 },
		{ 1, 1 },
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
	local frontier = util.Queue.new({ src })
	local cameFrom = {}
	print(frontier:len())
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
	end

	return path
end

util.Queue = Queue

return util
