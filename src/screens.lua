local conf = require("conf")
local game = require("game")
local levels = require("levels")
local tiles = require("tiles")
local util = require("util")

local screens = {}

--- Shows the game title and credits.
local MainScreen = {}

--- Creates a new main screen.
function screens.newMainScreen(engine)
	local self = {}
	setmetatable(self, { __index = MainScreen })

	self.engine = engine
	self.age = 0

	return self
end

--- Handles the update callback.
function MainScreen:update(dt)
	self.age = self.age + dt
end

--- Handles the keypressed callback.
function MainScreen:keypressed(key)
	if key == "space" then
		self.engine:push(screens.newMissionScreen(self.engine))
	end
end

--- Handles the draw callback.
function MainScreen:draw()
	love.graphics.setColor(conf.WHITE)
	love.graphics.draw(self.engine.titleBg, 0, 0)

	local x, _ = util.screenCenter()
	util.drawText("A GAME BY", self.engine.regular, conf.GREY, x, 95, util.ALING.CENTER)
	util.drawText("DIEGO BARBERA", self.engine.regular, conf.GREY, x, 105, util.ALING.CENTER)

	util.drawText(
		"< Press space to start >",
		self.engine.bold,
		util.flash(self.age, conf.WHITE, conf.GREY),
		x,
		125,
		util.ALING.CENTER
	)
end

--- Shows a mission description.
local MissionScreen = {}

--- Creates a new mission screen.
function screens.newMissionScreen(engine)
	local self = {}
	setmetatable(self, { __index = MissionScreen })

	self.engine = engine
	self.age = 0

	return self
end

--- Handles the update callback.
function MissionScreen:update(dt)
	self.age = self.age + dt
end

--- Handles the keypressed callback.
function MissionScreen:keypressed(key)
	if key == "space" then
		self.engine:pop()
		self.engine:push(screens.newGameScreen(self.engine))
	end
end

--- Handles the draw callback.
function MissionScreen:draw()
	love.graphics.setColor(conf.WHITE)
	love.graphics.draw(self.engine.missionBg, 0, 0)

	local x, _ = util.screenCenter()

	util.drawText("Enter the colony and defeat", self.engine.bold, conf.WHITE, x, 95, util.ALING.CENTER)
	util.drawText("the queen at level seven.", self.engine.bold, conf.WHITE, x, 115, util.ALING.CENTER)

	util.drawText(
		"< Press space to continue >",
		self.engine.bold,
		util.flash(self.age, conf.WHITE, conf.GREY),
		x,
		140,
		util.ALING.CENTER
	)
end

--- Returns the score calculated from the game stats: The deeper and more enemies killed
-- the higher the score would be, and there is a bonus for finishing each level in less
-- than 10 turns in average.
local function score(level, killCount, turnCount)
	return math.floor(level * 3 + killCount) + math.max(level * 10 - turnCount, 0)
end

--- Shows the states after losing the game.
local GameOverScreen = {}

--- Creates a new game over screen.
function screens.newGameOverScreen(engine, level, turnCount, killCount)
	local self = {}
	setmetatable(self, { __index = GameOverScreen })

	self.age = 0
	self.engine = engine
	self.level = level
	self.turnCount = turnCount
	self.killCount = killCount

	return self
end

--- Handles the update callback.
function GameOverScreen:update(dt)
	self.age = self.age + dt
end

--- Handles the keypressed callback.
function GameOverScreen:keypressed(key)
	if key == "space" then
		self.engine:pop()
		self.engine:push(screens.newGameScreen(self.engine))
	end
end

--- Handles the draw callback.
function GameOverScreen:draw()
	love.graphics.setColor(conf.WHITE)
	love.graphics.draw(self.engine.spaceBg, 0, 0)

	local x, _ = util.screenCenter()

	util.drawText("Your squad has died", self.engine.bold, conf.WHITE, x, 50, util.ALING.CENTER)

	util.drawText("Level", self.engine.regular, conf.WHITE, 135, 70)
	util.drawText(self.level, self.engine.regular, conf.WHITE, 175, 70)

	util.drawText("Turns taken", self.engine.regular, conf.WHITE, 103, 80)
	util.drawText(self.turnCount, self.engine.regular, conf.WHITE, 175, 80)

	util.drawText("Bugs killed", self.engine.regular, conf.WHITE, 106, 90)
	util.drawText(self.killCount, self.engine.regular, conf.WHITE, 175, 90)

	util.drawText("Score", self.engine.regular, conf.WHITE, 134, 100)
	util.drawText(score(self.level, self.killCount, self.turnCount), self.engine.regular, conf.WHITE, 175, 100)

	util.drawText(
		"< Press space to try again >",
		self.engine.bold,
		util.flash(self.age, conf.WHITE, conf.GREY),
		x,
		120,
		util.ALING.CENTER
	)
end

--- Shows the stats after wining the game.
local VictoryScreen = {}

--- Creates a new victory screen.
function screens.newVictoryScreen(engine, level, turnCount, killCount)
	local self = {}
	setmetatable(self, { __index = VictoryScreen })

	self.age = 0
	self.engine = engine
	self.level = level
	self.turnCount = turnCount
	self.killCount = killCount

	return self
end

--- Handles the update callback.
function VictoryScreen:update(dt)
	self.age = self.age + dt
end

--- Handles the keypressed callback.
function VictoryScreen:keypressed(key)
	if key == "space" then
		self.engine:pop()
	end
end

--- Handles the draw callback.
function VictoryScreen:draw()
	love.graphics.setColor(conf.WHITE)
	love.graphics.draw(self.engine.spaceBg, 0, 0)

	local x, _ = util.screenCenter()

	util.drawText("Victory", self.engine.bold, conf.WHITE, x, 45, util.ALING.CENTER)
	util.drawText("Your squad defeated the queen.", self.engine.bold, conf.WHITE, x, 60, util.ALING.CENTER)

	util.drawText("Turns taken", self.engine.regular, conf.WHITE, 103, 80)
	util.drawText(self.turnCount, self.engine.regular, conf.WHITE, 175, 80)

	util.drawText("Bugs killed", self.engine.regular, conf.WHITE, 106, 90)
	util.drawText(self.killCount, self.engine.regular, conf.WHITE, 175, 90)

	util.drawText("Score", self.engine.regular, conf.WHITE, 134, 100)
	util.drawText(score(self.level, self.killCount, self.turnCount), self.engine.regular, conf.WHITE, 175, 100)

	util.drawText(
		"< Press space to quit >",
		self.engine.bold,
		util.flash(self.age, conf.WHITE, conf.GREY),
		x,
		120,
		util.ALING.CENTER
	)
end

--- Shows the board and HUD for a given game run.
local GameScreen = {}

--- Creates a new game screen.
function screens.newGameScreen(engine)
	local self = {}
	setmetatable(self, { __index = GameScreen })

	self.engine = engine
	self.level = 1
	self.turnCount = 0
	self.killCount = 0

	self.game = game.newGame(self.level)
	self.gamePanel = screens.newGamePanel(engine, self.game, 80, 10)

	self.moveBtn = screens.newSpriteButton(engine, 37, "1", 8, 120, function()
		self.game:selectAction(game.ACTION.MOVE)
	end)
	self.shootBtn = screens.newSpriteButton(engine, 45, "2", 8 + conf.SPRITE_SIZE, 120, function()
		self.game:selectAction(game.ACTION.SHOOT)
	end)
	self.hitBtn = screens.newSpriteButton(engine, 53, "3", 8 + conf.SPRITE_SIZE * 2, 120, function()
		self.game:selectAction(game.ACTION.HIT)
	end)

	self.turnBtn = screens.newLabelButton(engine, "End turn", 8, 150, function()
		self.game:endPlayerTurn()
	end)

	return self
end

--- Handles the keypressed callback.
function GameScreen:keypressed(key)
	self.game:keypressed(key)
end

--- Handles the mousepressed callback.
function GameScreen:mousepressed(x, y, button)
	self.gamePanel:mousepressed(x, y, button)
	self.moveBtn:mousepressed(x, y, button)
	self.shootBtn:mousepressed(x, y, button)
	self.hitBtn:mousepressed(x, y, button)
	self.turnBtn:mousepressed(x, y, button)
end

--- Handles the update callback.
function GameScreen:update(dt)
	self.game:update(dt)

	if self.game.state == game.STATE.GAME_OVER then
		self:trackStats()

		self.engine:pop()
		self.engine:push(screens.newGameOverScreen(self.engine, self.level, self.turnCount, self.killCount))
	elseif self.game.state == game.STATE.VICTORY then
		self:trackStats()

		if self.level == levels.MAX_LEVEL then
			self.engine:pop()
			self.engine:push(screens.newVictoryScreen(self.engine, self.level, self.turnCount, self.killCount))
		else
			self.level = self.level + 1
			self.game = game.newGame(self.level, self.game.playerUnits)
			self.gamePanel.game = self.game
		end
	end
end

--- Draws the unit health bar.
local function drawHealthbar(x, y, health, maxHealth, centered, borderColor, damage)
	borderColor = borderColor or conf.WHITE
	local w = 4 * maxHealth + 1 - (1 * (maxHealth - 1))

	if centered then
		x = x - (w / 2)
	end

	util.drawRectangle("fill", x, y - 8, 4 * health, 5, conf.BLACK)
	util.drawRectangle("line", x, y - 8, w, 5, borderColor)

	for i = 1, maxHealth do
		local color = conf.LIME
		if i > health then
			color = conf.BLACK
		elseif damage and i > health - damage then
			color = conf.RED
		end

		local xi, yi = x + 3 * (i - 1) + 1, y - 7
		util.drawRectangle("fill", xi, yi, 3, 3, color)
		util.drawRectangle("line", xi, yi, 3, 3, conf.BLACK)
	end
end

-- Aggregates the current level stats with the ones for the whole game run.
function GameScreen:trackStats()
	local stats = self.game:stats()
	self.turnCount = self.turnCount + stats.turnCount
	self.killCount = self.killCount + stats.killCount
end

--- Delay to fade-in the screen at the beggining of the game.
local START_FADE_DELAY_SECONDS = 0.5

--- Handles the draw callback.
function GameScreen:draw()
	local padding = 8

	for i, unit in ipairs(self.game.playerUnits) do
		local x, y = padding, (conf.SPRITE_SIZE * (i - 1) + 4 * i) + padding
		self.engine.sprites:draw(unit.kind.spriteID, x, y, unit:isAlive() and 1 or 0.3)

		local color = self.game.selectedUnit == unit and conf.WHITE or conf.GREY
		util.drawRectangle("line", x, y, conf.SPRITE_SIZE, conf.SPRITE_SIZE, color)

		drawHealthbar(x + 18, y + 8, unit.health, unit.kind.maxHealth, false, color)
	end

	local hoveredUnit = self.gamePanel:getHoveredUnit()
	if self.game.state == game.STATE.PLAYER_TURN and hoveredUnit and hoveredUnit.kind.isEnemy then
		local x, y = 250, 150

		self.engine.sprites:draw(hoveredUnit.kind.spriteID, x, y)
		util.drawRectangle("line", x, y, conf.SPRITE_SIZE, conf.SPRITE_SIZE, conf.GREY)
		drawHealthbar(x + 18, y + 8, hoveredUnit.health, hoveredUnit.kind.maxHealth, false, conf.GREY)
		util.drawText(hoveredUnit.kind.name, self.engine.regular, conf.GREY, x + 18, y + 8)
	end

	self.gamePanel:draw()

	if self.game.selectedUnit then
		local unit = self.game.selectedUnit
		local y = 100

		self.engine.sprites:draw(unit.kind.spriteID, padding, y)
		util.drawRectangle("line", padding, y, conf.SPRITE_SIZE, conf.SPRITE_SIZE, conf.WHITE)
		drawHealthbar(padding + 18, y + 8, unit.health, unit.kind.maxHealth, false, conf.WHITE)
		util.drawText(unit.kind.name, self.engine.regular, conf.WHITE, padding + 18, y + 8)

		self.moveBtn:draw(self.game:isMoving(), self.game.selectedUnit.hasMoved)
		self.shootBtn:draw(self.game:isShooting(), self.game.selectedUnit.hasShot)
		self.hitBtn:draw(self.game:isHitting(), self.game.selectedUnit.hasHit)
	end

	if self.game.state == game.STATE.PLAYER_TURN then
		self.turnBtn:draw()
	end

	util.drawText("Level " .. self.level, self.engine.regular, conf.WHITE, 260, 10)
	love.graphics.draw(self.engine.minimap, 270, 24)
	util.drawRectangle("fill", 270, 24 + (10 * self.level), conf.SPRITE_SIZE, 100, conf.BLACK, 0.5)

	if self.game.state == game.STATE.START_TRANSITION then
		util.drawRectangle(
			"fill",
			0,
			0,
			conf.SCREEN_WIDTH,
			conf.SCREEN_HEIGHT,
			conf.BLACK,
			1 - self.game.stateSince - START_FADE_DELAY_SECONDS
		)
	elseif self.game.state == game.STATE.PLAYER_TURN_TRANSITION then
		self:drawMessage("PLAYER TURN")
	elseif self.game.state == game.STATE.ENEMY_TURN_TRANSITION then
		self:drawMessage("ENEMY TURN")
	elseif self.game.state == game.STATE.GAME_OVER_TRANSITION then
		self:drawMessage("GAME OVER")
	elseif self.game.state == game.STATE.VICTORY_TRANSITION then
		if self.level == levels.MAX_LEVEL then
			self:drawMessage("VICTORY")
		else
			self:drawMessage("LEVEL COMPLETED")
		end
	end
end

--- Draws an message overlay on the center of the screen. Only a message can be shown at a given time.
function GameScreen:drawMessage(msg)
	local centerX, centerY = util.screenCenter()
	local height, padding = 30, 2
	local y = centerY - height / 2

	util.drawRectangle("fill", 0, y, conf.SCREEN_WIDTH, height, conf.BLACK)
	util.drawRectangle("line", padding, y + padding, conf.SCREEN_WIDTH - padding * 2, height - padding * 2, conf.WHITE)
	util.drawText(msg, self.engine.bold, conf.WHITE, centerX, y + 11, util.ALING.CENTER)
end

--- Displays the game board.
local GamePanel = {}

--- Creates a new game panel.
function screens.newGamePanel(engine, game, x, y)
	local self = {}
	setmetatable(self, { __index = GamePanel })

	self.engine = engine
	self.game = game
	self.x = x
	self.y = y

	return self
end

--- Handles the mousepressed callback.
function GamePanel:mousepressed(x, y, button)
	if not self:isInbounds(x, y) then
		return
	end

	local gameX, gameY = self:gameCoords(x, y)
	self.game:mousepressed(gameX, gameY, button)
end

--- Checks whether the given position is in the bounds of the game panel.
function GamePanel:isInbounds(x, y)
	local size = conf.GRID_SIZE * conf.SPRITE_SIZE
	return util.isInRect(self.x, self.y, size, size, x, y)
end

--- Transform the given position from game coordinates to screen coordinates.
function GamePanel:screenCoords(gameX, gameY)
	return self.x + gameX * conf.SPRITE_SIZE, self.y + gameY * conf.SPRITE_SIZE
end

--- Transforms the given positon from screen coordinates to game coordinates.
function GamePanel:gameCoords(x, y)
	local gameX = math.floor((x - self.x) / conf.SPRITE_SIZE)
	local gameY = math.floor((y - self.y) / conf.SPRITE_SIZE)
	return gameX, gameY
end

--- Returns the unit hovered by the mouse. If there is none it returns nil.
function GamePanel:getHoveredUnit()
	local gameX, gameY = self:getGameCursorPosition()
	return self.game:getUnitAt(gameX, gameY)
end

--- Returns the unit being targeted by the selected unit and action. If there
-- is none it returns nil.
function GamePanel:getTargetedUnit()
	if not self.game.selectedUnit then
		return nil
	end

	local hoveredUnit = self:getHoveredUnit()
	if not hoveredUnit or not hoveredUnit.kind.isEnemy then
		return nil
	end

	if self.game:isShooting() and self.game:canShoot(self.game.selectedUnit, hoveredUnit) then
		return hoveredUnit
	elseif self.game:isHitting() and self.game:canHit(self.game.selectedUnit, hoveredUnit) then
		return hoveredUnit
	end

	return nil
end

--- Returns the selected unit if there is any. If there is none it returs the hovered unit.
function GamePanel:getPlayableUnit()
	if self.game.selectedUnit then
		return self.game.selectedUnit
	end

	return self:getHoveredUnit()
end

--- Returns the position of the mouse in the game grid.
function GamePanel:getGameCursorPosition()
	local x, y = love.mouse.getPosition()
	x, y = util.scaledCoords(x, y, conf.SCALE)
	return self:gameCoords(x, y)
end

--- Handles the draw callback.
function GamePanel:draw()
	self:drawGrid()

	if self.game.state == game.STATE.PLAYER_TURN then
		if self.game.selectedUnit then
			local x, y = self:screenCoords(self.game.selectedUnit.x, self.game.selectedUnit.y)
			util.drawRectangle("line", x, y, 16, 16, conf.LIME)
		end

		self:drawPlayableTiles()
		self:drawCursor()
	end

	-- draw the shadows before the units to ensure that they are below them
	for _, unit in ipairs(self.game.playerUnits) do
		self:drawUnitShadow(unit)
	end

	for _, unit in ipairs(self.game.enemyUnits) do
		self:drawUnitShadow(unit)
	end

	for _, unit in ipairs(self.game.playerUnits) do
		self:drawUnit(unit)
	end

	for _, unit in ipairs(self.game.enemyUnits) do
		self:drawUnit(unit)
	end

	if self.game.state == game.STATE.PLAYER_TURN then
		-- draw the indicators after the units to ensure that the overlap
		local hoveredUnit = self:getHoveredUnit()

		for _, unit in ipairs(self.game.playerUnits) do
			self:drawUnitIndicators(unit, unit == self.selectedUnit, unit == hoveredUnit)
		end

		local targetedUnit = self:getTargetedUnit()
		for _, unit in ipairs(self.game.enemyUnits) do
			self:drawUnitIndicators(unit, unit == self.selectedUnit, unit == hoveredUnit, unit == targetedUnit)
		end
	end
end

--- Draws the game grid.
function GamePanel:drawGrid()
	for i = 0, conf.GRID_SIZE - 1 do
		for j = 0, conf.GRID_SIZE - 1 do
			local t = tiles.KIND[self.game.map[j + 1][i + 1]]
			self.engine.sprites:draw(t.spriteID, self.x + i * conf.SPRITE_SIZE, self.y + j * conf.SPRITE_SIZE)
		end
	end
end

--- Highlights the tiles that are playable according to the selected action.
function GamePanel:drawPlayableTiles()
	local playableUnit = self:getPlayableUnit()

	if not playableUnit then
		return
	end

	local actions

	if playableUnit.kind.isEnemy then
		-- for an enemy unit we display the largest attack range
		if playableUnit.kind.shotDamage > 0 then
			actions = self.game:allowedShots(playableUnit)
		else
			actions = self.game:allowedHits(playableUnit)
		end
	else
		-- for a player unit we display the selected action range
		actions = self.game:allowedActions(playableUnit)
	end

	for _, pos in ipairs(actions) do
		local x, y = self:screenCoords(pos.x, pos.y)

		local color = conf.LIME
		if playableUnit.kind.isEnemy then
			color = conf.RED
		elseif self.game.action == game.ACTION.SHOOT then
			color = conf.YELLOW
		elseif self.game.action == game.ACTION.HIT then
			color = conf.BLUE
		end

		util.drawRectangle("fill", x, y, 16, 16, color, 0.4)
	end
end

--- Draws the squared cursor on the board.
function GamePanel:drawCursor()
	local gameX, gameY = self:getGameCursorPosition()
	local target = self.game:getUnitAt(gameX, gameY)

	local color = conf.WHITE
	if target and target == self.game.selectedUnit then
		color = conf.LIME
	elseif self.game:canTarget(gameX, gameY) then
		color = conf.YELLOW
	end

	if self.game:isInbounds(gameX, gameY) then
		local x, y = self:screenCoords(gameX, gameY)
		util.drawRectangle("line", x, y, 16, 16, color)
	end
end

--- Draws the shadow effect for a unit.
function GamePanel:drawUnitShadow(unit)
	if not unit:isAlive() then
		return
	end

	local x, y = self:screenCoords(unit.x, unit.y)
	self.engine.sprites:draw(17, x, y)
end

--- Draws a unit in the board, and fades it out when it dies according to the configured animation duration.
function GamePanel:drawUnit(unit)
	if not unit:isAlive() and unit.deathAge > conf.ANIMATION_DURATION_SECONDS then
		return
	end

	local x, y = self:screenCoords(unit.x, unit.y)
	self.engine.sprites:draw(
		unit.kind.spriteID,
		x,
		y - 3,
		(conf.ANIMATION_DURATION_SECONDS - unit.deathAge) / conf.ANIMATION_DURATION_SECONDS
	)

	if unit.lastDamage > 0 then
		self:drawDamage(unit.lastDamage, unit.lastDamageAge, x, y - 3)
	end
end

--- Draws the unit health and action indicators
function GamePanel:drawUnitIndicators(unit, isSelected, isHovered, isTargeted)
	local x, y = self:screenCoords(unit.x, unit.y)
	local showHealthBar = isSelected or isHovered
	local damage = 0

	if isTargeted then
		damage = self.game:getActionDamage()
	end

	if showHealthBar then
		drawHealthbar(x + (conf.SPRITE_SIZE / 2), y - 3, unit.health, unit.kind.maxHealth, true, nil, damage)
	end

	if not unit:isPlayer() then
		return
	end

	if self.game:isPendingUnit(unit) then
		local spriteID = unit.hasMoved and 20 or 19
		self.engine.sprites:draw(spriteID, x, y - conf.SPRITE_SIZE - (showHealthBar and 9 or 0) - 3)
	end
end

--- Sprite IDs to use for the damage animations.
local DAMAGE_SPRITE_IDS = { 36, 44, 52 }

--- Draws a damage animation that fades in with age according to the configured animation duration.
function GamePanel:drawDamage(damage, age, x, y)
	if age > conf.ANIMATION_DURATION_SECONDS then
		return
	end

	self.engine.sprites:draw(
		DAMAGE_SPRITE_IDS[damage],
		x,
		y,
		(conf.ANIMATION_DURATION_SECONDS - age) / conf.ANIMATION_DURATION_SECONDS
	)
end

--- A button shaped with a single sprite.
local SpriteButton = {}

--- Creates a new sprite button.
function screens.newSpriteButton(engine, spriteID, caption, x, y, func)
	local self = {}
	setmetatable(self, { __index = SpriteButton })

	self.engine = engine
	self.spriteID = spriteID
	self.caption = caption
	self.x = x
	self.y = y
	self.w = conf.SPRITE_SIZE
	self.h = conf.SPRITE_SIZE
	self.func = func

	return self
end

--- Checks whether the button is being hovered.
function SpriteButton:isHovered()
	local mx, my = love.mouse.getPosition()
	mx, my = util.scaledCoords(mx, my, conf.SCALE)
	return util.isInRect(self.x, self.y, self.w, self.h, mx, my)
end

--- Handles the mousepressed callback.
function SpriteButton:mousepressed(x, y, button)
	if button ~= 1 then
		return
	end

	if util.isInRect(self.x, self.y, self.w, self.h, x, y) then
		self.func()
	end
end

--- Handles the draw callback.
function SpriteButton:draw(selected, disabled)
	local spriteID = self.spriteID
	local color = conf.GREY

	if disabled then
		spriteID = spriteID + 3
		color = conf.DARK_GREY
	elseif selected then
		spriteID = spriteID + 2
		color = conf.WHITE
	elseif self:isHovered() then
		spriteID = spriteID + 1
		color = conf.LIGHT_BLUE
	end

	self.engine.sprites:draw(spriteID, self.x, self.y)
	util.drawText(
		self.caption,
		self.engine.regular,
		color,
		self.x + conf.SPRITE_SIZE / 2,
		self.y + 17,
		util.ALING.CENTER
	)
end

--- A button with a text label.
local LabelButton = {}

--- Creates a new label button.
function screens.newLabelButton(engine, label, x, y, func)
	local self = {}
	setmetatable(self, { __index = LabelButton })

	self.engine = engine
	self.label = label
	self.x = x
	self.y = y
	self.w = conf.SPRITE_SIZE * 4
	self.h = conf.SPRITE_SIZE
	self.func = func

	return self
end

--- Checks whether the button is being hovered.
function LabelButton:isHovered()
	local mx, my = love.mouse.getPosition()
	mx, my = util.scaledCoords(mx, my, conf.SCALE)
	return util.isInRect(self.x, self.y, self.w, self.h, mx, my)
end

--- Handles the mousepressed callback.
function LabelButton:mousepressed(x, y, button)
	if button ~= 1 then
		return
	end

	if util.isInRect(self.x, self.y, self.w, self.h, x, y) then
		self.func()
	end
end

--- Handles the draw callback.
function LabelButton:draw(disabled)
	local shift = 0
	local color = conf.GREY
	if self:isHovered() and not disabled then
		shift = 8
		color = conf.LIGHT_BLUE
	end

	self.engine.sprites:draw(22 + shift, self.x, self.y)
	self.engine.sprites:draw(23 + shift, self.x + conf.SPRITE_SIZE, self.y)
	self.engine.sprites:draw(23 + shift, self.x + conf.SPRITE_SIZE * 2, self.y)
	self.engine.sprites:draw(24 + shift, self.x + conf.SPRITE_SIZE * 3, self.y)
	util.drawText(
		self.label,
		self.engine.regular,
		color,
		self.x + conf.SPRITE_SIZE * 4 / 2,
		self.y + 5,
		util.ALING.CENTER
	)
end

return screens
