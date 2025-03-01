dofile("ccrepo/lib/ak")
dofile("ccrepo/lib/enclave")

ak.project = "blkjk"

local drive, surface, font, gothic, screen, card_face, card_back, game, gW, gH, idleCards, deck, club, diamond, heart, spade

STAGE_BET  = 1
STAGE_HAND = 2

MAX_BET = 128

function init()
	running = true
	m       = peripheral.wrap("top")
	drive   = peripheral.find("drive")

	m.setTextScale(0.5)
	term.redirect(m)
	term.setPaletteColor(colors.lightGray, 0xc5c5c5)
	term.setPaletteColor(colors.orange   , 0xf15c5c)
	term.setPaletteColor(colors.gray     , 0x363636)
	term.setPaletteColor(colors.green    , 0x044906)

	surface    = dofile(ak:lib("surface"))
	font       = surface.loadFont(surface.load(ak:file("font")))
	gothic     = surface.loadFont(surface.load(ak:file("gothic")))
	gW, gH     = term.getSize()
	screen     = surface.create(gW, gH, colors.green)
	card_face  = surface.load(ak:file("card.nfp"))
	card_back  = surface.load(ak:file("back.nfp"))
	club       = surface.load(ak:file("club.nfp"))
	diamond    = surface.load(ak:file("diamond.nfp"))
	heart      = surface.load(ak:file("heart.nfp"))
	spade = surface.load(ak:file("spade.nfp"))
	game  	   = nil

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
	ak:shuffle(deck)
	idleCards = {}
	for i=1,4 do
		idleCards[i] = card_idle_new(math.random(gW), math.random(gH), deck[i]:sub(1, 1), deck[i]:sub(2, 10), colors.red)
	end
end

function get_centered_text_dims(text)
	local w, h = surface.getTextSize(text, font)
	local cw = math.floor(screen.width / 2 - w / 2)
	local ch = math.floor(screen.height / 2 - h / 2)
	return cw, ch
end

function button(x1, y1, x2, y2)
	local box = {}
	box[1] = x1
	box[2] = y1
	box[3] = x2
	box[4] = y2
	for i=1,4 do
		if box[i] == nil then
			error("called button() with nil argument")
		end
	end

	function pressed(clickX, clickY)
		if (clickX >= x1 and clickX <= x2) and (clickY >= y1 and clickY <= y2) then
			return true
		end
		return false
	end

	box.pressed = pressed
	return box
end

function place_bet(bet)
	local loop         = true
	local bet          = bet
	local increment    = 1
	local info         = ""
	local dbg_text     = ""
	local increase_bet = button(54, 46, 63, 50)
	local decrease_bet = button(18, 46, 27, 50)
	local place_bet    = button(30, 46, 51, 51)
	local balance = game.player.balance - bet

	if bet >= 8 then
		increment = 8
	end

	repeat
		screen:clear(colors.green)

		local xx = 28
		local yy = 45
		screen:fillRect(xx - 11, yy, 10, 5, colors.white)
		screen:drawText("<", font, xx-9, yy, colors.black)
		screen:fillRect(xx + 25, yy, 10, 5, colors.white)
		screen:drawText(">", font, xx+28, yy, colors.black)
		screen:fillRect(xx+1, yy, 22, 6, colors.white)

		screen:push(-1, -1, gW, gH)
		local balx, _ = get_centered_text_dims("Balance")
		local baly = 5
		local betx = balx+12
		--screen:drawText(dbg_text, font, balx, baly+13, colors.lime)
		screen:drawText(info, font, balx, baly+13, colors.lime)
		screen:drawText("Balance", font, balx+3, baly, colors.yellow)
		screen:drawText("$"..game.player.balance, font, balx+11, baly+8, colors.yellow)

		if bet >= 10 then
			betx = betx
		elseif bet >= 100 then
			betx = balx+7
		elseif bet >= 1000 then
			betx = balx+12
		end
		screen:drawText(""..bet, font, betx+4, baly+19, colors.red)

		screen:output()
		screen:pop()

		local event = {os.pullEvent("monitor_touch")}
		local x = event[3]
		local y = event[4]
		dbg_text = tostring(x)..", "..tostring(y)

		if increase_bet.pressed(x, y) then
			if balance < increment then
				info = "Broke!"
				goto place_bet_pass
			end
			if bet == MAX_BET then
				info = "Max bet!"
				goto place_bet_pass
			end
			bet = bet + increment
			balance = balance - increment
			if bet >= 8 then
				increment = 8
			end
			dbg_text = "increase!"
		elseif decrease_bet.pressed(x, y) then
			if bet < increment then
				goto place_bet_pass
			end
			if bet == 8 then
				increment = 1
			end
			bet = bet - increment
			balance = balance + increment
		elseif place_bet.pressed(x, y) then
			dbg_text = "bet!"
			if bet == 0 then goto place_bet_pass end
			loop = false
		end

		::place_bet_pass::
		os.sleep(0.01)
	until loop == false
	return bet
end

function player_new()
	local player     = {}
	player.id        = drive.getDiskID()
	player.balance   = 64
	player.name      = "default"
	player.valid     = true
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

	for _, card in ipairs(idleCards) do
		card_update(card)
		card_draw(card)
	end

	local text = "No cheating"
	local w, h = get_centered_text_dims(text)
	screen:drawText(text, font, w, h-10, colors.red)

	text = ":^)"
	w, h = get_centered_text_dims(text)
	screen:drawText(text, font, w, h, colors.red)
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

	screen:drawSurface(card_face, x, y)
	screen:push(x, y, 30, 30)
	screen:drawText(""..card.num, font, 2, 2, card.color)
	screen:pop()
end

function score(hand)
	for _, card in pairs(hand) do
	end
end

function game_hand()
	local user = {}
	user.score = 0
	user.hand  = {}
	return user
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

function draw_cards(cards, x, y, facedown)
	local base = x
	local scale = 17
	local offset = -2
	if #cards == 2 then
	elseif #cards == 3 then
		offset = -10
	elseif #cards == 4 then
		offset = -16
		scale = 15
	elseif #cards == 5 then
		offset = -20
		scale = 13
	elseif #cards == 6 then
		offset = -25
		scale = 11
	elseif #cards >= 7 then
		offset = -35
		scale = 9
	end

	for i, card in ipairs(cards) do
		local x = i * scale + (base + offset)
		if i == 2 and facedown then
			screen:drawSurface(card_back, x, y)
		else
		    draw_card_face(card, x, y)
		end
	end
end

function draw_board(dealer_hand, player_hand, facedown)
	draw_cards(dealer_hand, 12, 4, facedown)
	draw_cards(player_hand, 12, 25, false)

	if #dealer_hand < 5 then
		local deck_x = 67
		local deck_y = 0
		screen:drawSurface(card_back, deck_x, deck_y+1)
		screen:drawSurface(card_back, deck_x-1, deck_y)
	end
end

function score(hand)
	local total = 0
	for _, card in pairs(hand) do
		local c = card:sub(1, 1)
		if c == "1" then total = total + 1 end
		if c == "2" then total = total + 2 end
		if c == "3" then total = total + 3 end
		if c == "4" then total = total + 4 end
		if c == "5" then total = total + 5 end
		if c == "6" then total = total + 6 end
		if c == "7" then total = total + 7 end
		if c == "8" then total = total + 8 end
		if c == "9" then total = total + 9 end
		if c == "T" then total = total + 10 end
		if c == "J" then total = total + 10 end
		if c == "Q" then total = total + 10 end
		if c == "K" then total = total + 10 end
	end
	for _, card in pairs(hand) do
		local c = card:sub(1, 1)
		if c == "A" then
			if total + 11 > 21 then
			    total = total + 1
			else
			    total = total + 11
			end
		end

	end
	return total
end

function hotpath()
	if game == nil then
		game = new_game()
	end

	if game.player.valid == false then
		invalid()
		return
	end
	local input_stay_btn  = button(10, 44, 40, 51)
	local input_hit_btn   = button(45, 44, 67, 52)
	local double_down_btn = button(0, 0, 0, 0)
	local bet = 0

	--local input_stay_btn = button(0, 0, 0, 0)
	--local input_hit_btn  = button(0, 0, 0, 0)

	local playing = true
	repeat
		local dbg = "debug: "
		local epoch = 1
		local doubled_down = false
		bet = place_bet(bet)

		local dealer = game_hand()
		local player = game_hand()
		local deck_i    = 1
		local win_state = 0

		ak:shuffle(deck)
		dealer.hand[1] = deck[1]
		dealer.hand[2] = deck[2]

		player.hand[1] = deck[3]
		player.hand[2] = deck[4]
		deck_i = 4
		player.score = score(player.hand)
		dealer.score = score(dealer.hand)
		dbg = ""..tostring(player.score)

		local hitting = true
		while hitting do
			screen:clear(colors.green)
			draw_board(dealer.hand, player.hand, true)

			local x, y = get_centered_text_dims(dbg)
			--screen:drawText(dbg, font, 0, y+4, colors.lime)

			local input_y = 43
			local hit_x   = 15
			local stay_x  = hit_x+29

			screen:fillRect(hit_x-5,  input_y, 30, 8, colors.yellow)
			screen:fillRect(stay_x, input_y, 23, 8, colors.lime)

			screen:drawText("STAND", font, hit_x-4, input_y+2, colors.black)
			screen:drawText("HIT", font, stay_x+4, input_y+2, colors.black)

			if (game.player.balance) >= bet * 2 and epoch == 1 then -- DO X2
				double_down_btn = button(70, 46, 79, 52)
				screen:fillRect(70, 46, 79, 52, colors.red)
				screen:drawText("X2", font, 71, 47, colors.yellow)
			end

			screen:output()
			if epoch == 1 and player.score == 21 then
				win_state = 2
				os.sleep(1.1)
				goto end_game
			end

			local event = {os.pullEvent("monitor_touch")}
			local click_x = event[3]
			local click_y = event[4]
			--dbg = ""..tostring(x)..", "..tostring(y)
			dbg = ""..tostring(click_x)..", "..tostring(click_y)

			if input_hit_btn.pressed(click_x, click_y) then
				player.hand[#player.hand+1] = deck[deck_i]
				deck_i = deck_i + 1
				player.score = score(player.hand)
				dbg = ""..tostring(player.score)
			elseif input_stay_btn.pressed(click_x, click_y) then
				dbg = "STAY!"
				hitting = false
			elseif double_down_btn.pressed(click_x, click_y) then
				player.hand[#player.hand+1] = deck[deck_i]
				deck_i = deck_i + 1
				bet = bet * 2
				doubled_down = true
				hitting = false
			end

			if player.score >= 21 then hitting = false end

			epoch = epoch + 1
			os.sleep(0.01)
		end

		if player.score > 21 then
			win_state = 3
			goto end_game
		end

		screen:clear(colors.green)
		draw_board(dealer.hand, player.hand, true)
		screen:output()

		os.sleep(1)
		screen:clear(colors.green)
		draw_board(dealer.hand, player.hand, false)
		screen:output()
		os.sleep(2)

		dealer_i = 1
		while dealer.score < 17 do
			dealer.hand[#dealer.hand+1] = deck[deck_i]
			deck_i = deck_i + 1
			screen:clear(colors.green)
			draw_board(dealer.hand, player.hand, false)

			local x, y = get_centered_text_dims(dbg)

			local input_y = 43
			local hit_x   = 15
			local stay_x  = hit_x+29

			screen:output()
			dealer.score = score(dealer.hand)
			if dealer.score > 21 then
				win_state = 1
				goto end_game
			end
			os.sleep(4)
		end

		if player.score == dealer.score then
			win_state = 4
		elseif player.score > dealer.score then
			win_state = 1
		elseif dealer.score > 21 then
			win_state = 1
		end
		
		::end_game::
		local end_txt = ""
		local color    = colors.red
		if win_state == 0 then 	   -- PLAYER LOSS 
			end_txt = "YOU LOSE!"
			game.player.balance = game.player.balance - bet
		elseif win_state == 1 then -- PLAYER_WIN
			end_txt = "YOU WIN!"
			color = colors.lime
			game.player.balance = game.player.balance + bet
		elseif win_state == 2 then -- BLACKJACK
			end_txt = "BLACKJACK!"
			game.player.balance = game.player.balance + bet*2
			color = colors.yellow
		elseif win_state == 3 then -- BUST
			end_txt = "BUST!"
			game.player.balance = game.player.balance - bet
		elseif win_state == 4 then -- PUSH
			end_txt = "PUSH!"
			color = colors.white
		end
		screen:clear(colors.green)
		draw_board(dealer.hand, player.hand, false)
		local end_x, end_y = get_centered_text_dims(end_txt)
		screen:drawText(end_txt, font, end_x, end_y-7, color)
		screen:output()
		if doubled_down then
			bet = bet / 2
		end
		if bet > game.player.balance then
			bet = 0
		end
		os.sleep(5)
		if game.player.balance == 0 then
			playing = false 
			screen:clear(colors.green)
			local bust = "You busted!"
			local bx, by = get_centered_text_dims(bust)
			screen:drawText(bust, font, bx, by, colors.red)
			screen:output()
			os.sleep(10)
			eject()
			return
		end 
	until playing == false
end

function card_idle_new(x, y, num, suit, color)
	local card    = {}
	card.delta    = 1
	card.posX     = x
	card.posY     = y
	card.deltaX   = card.delta
	card.deltaY   = card.delta
	card.boxX     = 68
	card.boxY     = 38
	card.negX     = -1
	card.negY     = -1
	card.num      = num
	card.suit     = suit
	card.color    = color
	card.facedown = false
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
	if not drive.isDiskPresent() and false then
		idle()
	else
		hotpath()
	end
	os.sleep(0.01)
end
