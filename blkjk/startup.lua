local running, monitor, drive, surface, font, screen, cardBg, gameState, w, h, idleCards, deck

STAGE_BET  = 1
STAGE_HAND = 2

MAX_BET = 32

function init()
	running = true
	m       = peripheral.find("monitor")
	drive   = peripheral.find("drive")

	m.setTextScale(0.5)
	term.redirect(m)
	term.setPaletteColor(colors.lightGray, 0xc5c5c5)
	term.setPaletteColor(colors.orange, 0xf15c5c)
	term.setPaletteColor(colors.gray, 0x363636)
	term.setPaletteColor(colors.green, 0x044906)

	surface    = dofile("surface")
	font       = surface.loadFont(surface.load("font"))
	w, h       = term.getSize()
	screen     = surface.create(w, h, colors.green)
	cardBg     = surface.load("card.nfp")
	gameState  = nil

	deck = {}
	local i = 1
	for _, suit in ipairs({"heart", "diamond", "club", "spade"}) do
		for _, num in ipairs({"A", "T", "J", "Q", "K"}) do
			deck[i] = num..suit;
			i = i + 1
		end
		for num = 2, 9, 1 do
			deck[i] = tostring(num)..suit;
			i = i + 1
		end
	end

	idleCards = {}
	for i=1,5 do
		idleCards[i] = card_idle_new(math.random(w), math.random(h), deck[i]:sub(1, 1), deck[i]:sub(2, 10), colors.red)
	end
end

function place_bet()
	local loop = true
	local bet  = 175

	repeat
		screen:clear(colors.green)

		local xx = 17
		local yy = 32
		screen:fillRect(xx - 10, yy, 7, 3, colors.white)
		screen:fillRect(xx + 25, yy, 7, 3, colors.white)

		screen:fillRect(xx, yy-3, 22, 6, colors.white)

		local bal_color = colors.orange
		local bal = "$"..gameState.player.bal-bet
		screen:push(-1, -1, w, h)
		local balx = 15
		local baly = 3
		local betx = balx+12
		screen:drawText("Balance", font, balx, baly, bal_color)
		screen:drawText(bal, font, balx+3, baly+6, bal_color)

		if bet >= 100 then
			betx = balx+7
		elseif bet >= 1000 then
			betx = balx+12
		end
		screen:drawText(""..bet, font, betx, baly+19, bal_color)

		screen:output()
		screen:pop()

		local eventData = {os.pullEvent()}
		local event = eventData[1]

		if event == "mouse_click" then
			local button, x, y
			button = eventData[2]
			x = eventData[3]
			y = eventData [4]
		end
		sleep(0.05)
	until loop == false
	return bet
end

function player_new()
	local player = {}
	player.id    = drive.getDiskID()
	player.bal   = 1000
	player.name  = "default"
	player.valid = true 
	return player
end

function idle()
	screen:clear(colors.green)
	for _, card in ipairs(idleCards) do
		card_update(card)
	end
	for _, card in ipairs(idleCards) do
		card_draw(card)
	end
	screen:output()
end

function invalid()
	screen:clear(colors.green)
	local text = "No cheating :^)"
	local w, h = surface.getTextSize(text, font)
	screen:drawText(text, font, math.floor(screen.width / 2 - w / 2), math.floor(screen.height / 2 -  h / 2), colors.red)
	screen:output()
	-- TODO: Eject
end

function new_game()
	local game = {}
	game.player = player_new()
	game.op     = STAGE_BET
	return game  
end

function card_draw(card)
	local x, y
	x = card.posX
	y = card.posY

	screen:drawSurface(cardBg, x, y)
	screen:push(x, y, 30, 30)
	screen:drawText(""..card.num, font, 2, 2, card.color)
	screen:pop()
end

function hotpath()
	if gameState == nil then
		gameState = new_game()
		if gameState.player.valid == false then
			invalid()
			return
		end
	end

	if gameState.op == STAGE_BET then
		local bet = place_bet()
	elseif gameState.op == STAGE_HAND then
		screen:clear(colors.green)
		screen:output()
	end
end

function card_idle_new(x, y, num, suit, color)
	local card = {}
	card.delta = 1
	card.posX   = x
	card.posY   = y
	card.deltaX = card.delta
	card.deltaY = card.delta
	card.boxX   = 45
	card.boxY   = 24
	card.negX   = -1
	card.negY   = -1
	card.num    = num
	card.suit   = suit
	card.color  = color
	return card
end

function card_update(card)
	card.posX = card.posX + card.deltaX
	card.posY = card.posY + card.deltaY
	if card.posX >= card.boxX then
		card.deltaX = -card.delta
	end
	if card.posY >= card.boxY then
		card.deltaY = -card.delta
	end
	if card.posX <= card.negX then
		card.deltaX = card.delta
	end
	if card.posY <= card.negY then
		card.deltaY = card.delta
	end
end

init()
while true do
	if not drive.isDiskPresent() then
		idle()
	else
		hotpath(card)
	end
	os.sleep(0.01)
end
