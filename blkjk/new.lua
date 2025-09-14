--
-- Created by Justin Tunheim 9/7/25
-- 

dofile("ccrepo/lib/ak")
ak.project = "blkjk"

OP_IDLE = "idle"
OP_BET  = "bet"
OP_GAME = "game"

local aspect, drive, surface, font, gothic, screen, card_face, card_back, gW, gH
local state = {
	idle_cards = {},
	header = {},
	status = {
		op = OP_BET,
	},
	game = {
		bet = 0,
		increment = 0,
	},
	MAX_BET = 128,
}

function init()
	state.header[1] = "Chedda's"
	state.header[2] = "Black"
	state.header[3] = "Jack"
	m     = peripheral.find("monitor") or error("monitor is required for blackjack machine.")
	drive = peripheral.find("drive") or error("disk drive required for blackjack machine.")
	m.setTextScale(0.5)
	term.redirect(m)
	term.setPaletteColor(colors.lightGray, 0xc5c5c5)
	term.setPaletteColor(colors.orange   , 0xf15c5c)
	term.setPaletteColor(colors.gray     , 0x363636)
	term.setPaletteColor(colors.green    , 0x044906)
	term.clear()

	surface    = dofile(ak:lib("surface"))
	font       = surface.loadFont(surface.load(ak:asset("font")))
	gothic     = surface.loadFont(surface.load(ak:asset("gothic")))
	gW, gH     = term.getSize()
	screen     = surface.create(gW, gH, colors.green)
	aspect     = screen.width / screen.height
	card_face  = surface.load(ak:file("card.nfp"))
	card_back  = surface.load(ak:file("back.nfp"))
	club       = surface.load(ak:file("club.nfp"))
	diamond    = surface.load(ak:file("diamond.nfp"))
	heart      = surface.load(ak:file("heart.nfp"))
	spade 	   = surface.load(ak:file("spade.nfp"))

	deck = {}
	local i = 1
	for j=1,8 do -- 8 deck dealer
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
	end

	ak:shuffle(deck)
	idleCards = {}
	idle_count = gH / 10
	for i=1,idle_count do
		state.idle_cards[i] = card_idle_new(math.random(70), math.random(60), deck[i]:sub(1, 1), deck[i]:sub(2, 10), colors.red, deck[i])
	end
end

function card_idle_new(x, y, num, suit, color, card_str)
	local card    = {}
	card.str      = card_str
		
	card.delta    = 1
	card.posX     = x
	card.posY     = y
	if math.random(2) > 1 then
			card.deltaX = -card.delta
	else
			card.deltaX = card.delta
	end
	if math.random(2) > 1 then
			card.deltaY   = -card.delta
	else
			card.deltaY   = card.delta
	end
	card.boxX     = gW - 10
	card.boxY     = gH - 14
	card.negX     = -1
	card.negY     = -1
	card.num      = num
	card.suit     = suit
	card.color    = color
	card.facedown = false
	return card
end

function get_centered_txt(text)
	local w, h = surface.getTextSize(text, font)
	local cw = math.floor(screen.width / 2 - w / 2)
	local ch = math.floor(screen.height / 2 - h / 2)
	return cw, ch
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

function draw_card_face(card, x, y)
	local color = colors.red
	local suite = card:sub(2, 10)
	local suite_icon = nil

	if suite == "spade" then
		color = colors.black
		suite_icon = spade
	elseif suite == "club" then
		color = colors.black
		suite_icon = club
	elseif suite == "heart" then
		suite_icon = heart
	elseif suite == "diamond" then
		color = colors.black
		suite_icon = diamond
	end

	screen:drawSurface(card_face, x, y)
	screen:push(x, y, 30, 30)
	local card_i = card:sub(1, 1)
	if card_i == "T" then
		card_i = "10"
	end
	screen:drawText(card_i, font, 2, 2, color)
	screen:drawSurface(suite_icon, 5, 8)

	screen:pop()
end

function debug_outline()
	local width = 79
	local height = 52
	if screen.width ~= width or screen.height ~= height then
		local txt = ""..screen.width..", "..screen.height
		local x, y = get_centered_txt(txt)
		screen:drawText(txt, font, x, y, colors.lime)
		screen:drawLine(0, 0, 0, height-1, colors.red)
		screen:drawLine(0, 0, width-1, 0, colors.red)
		screen:drawLine(0, height-1, width-1, height-1, colors.red)
		screen:drawLine(width-1, 0, width-1, height-1, colors.red)
	end
end

init()
while true do
	screen:clear(colors.green)

	if state.status.op == OP_IDLE then
		for _, card in ipairs(state.idle_cards) do
			card_update(card)
			draw_card_face(card.str, card.posX, card.posY)
		end
		local header_w, header_h = get_centered_txt(state.header[1])
		local black_w, black_h = get_centered_txt(state.header[2])
		local jack_w, jack_h = get_centered_txt(state.header[3])
		screen:drawText(state.header[1], gothic, header_w-20, header_h-25, colors.yellow)
		screen:drawText(state.header[2], gothic, black_w-14, black_h-10, colors.black)
		screen:drawText(state.header[3], gothic, jack_w-5, jack_h+5, colors.white)
	elseif state.status.op == OP_BET then
	end

	debug_outline()
	screen:output()
	os.sleep(0.01)
end
