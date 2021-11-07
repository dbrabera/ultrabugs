local util = {}

function util.scaledCoords(x, y, scale)
	return math.floor(x / scale), math.floor(y / scale)
end

return util
