dofile("ccrepo/lib/ak")
dofile("ccrepo/lib/surface")
ak.project = "sep"

local gBLOCK = false -- global blocking "lock"
local drive, surface, screen, font, monitor, bg_color, player, touch_x, touch_y

function init()
	monitor = peripheral.wrap("top") or error("output monitor needed for teller machine operation.")
	drive   = peripheral.find("drive") or error("disk drive required for teller machine operation.")
	monitor.setTextScale(0.5)
	term.redirect(monitor)

	term.setPaletteColor(colors.lightGray, 0xc5c5c5)
	term.setPaletteColor(colors.orange   , 0xf15c5c)
	term.setPaletteColor(colors.gray     , 0x363636)
	term.setPaletteColor(colors.green    , 0x044906)
	bg_color = colors.green

	surface    = dofile(ak:lib("surface"))
	font       = surface.loadFont(surface.load("ccrepo/blkjk/font"))
	local w, h = term.getSize()
	screen     = surface.create(w, h, bg_color)
	player     = {}
	touch_x    = -1
	touch_y    = -1
	screen:clear(bg_color)
end

function get_centered_text_dims(text)
	local w, h = surface.getTextSize(text, font)
	local cw = math.floor(screen.width / 2 - w / 2)
	local ch = math.floor(screen.height / 2 - h / 2)
	return cw, ch
end

function idle()
	screen:clear(bg_color)
	local head = "Bank"
	local mid  = "of"
	local foot = "Chedda"
		
	local x, y = get_centered_text_dims(head)
	screen:drawText(head, font, x, y-(y/2), colors.yellow)

	local x, y = get_centered_text_dims(mid)
	screen:drawText(mid, font, x, y, colors.yellow)

	local x, y = get_centered_text_dims(foot)
	screen:drawText(foot, font, x, y+(y/2), colors.yellow)
	screen:output()
end

function empty()
	turtle.turnRight()
	turtle.drop(64)
	turtle.turnLeft()
end

function discard()
	turtle.turnLeft()
	turtle.drop(64)
	turtle.turnRight()
end

function draw()
	local dbg_txt  = tostring(touch_x)..", "..tostring(touch_y)
	screen:clear(bg_color)
	local x, y = get_centered_text_dims(player.name)
	screen:drawText(player.name, font, x, y-(y/2)-(y/2), colors.yellow)
	local bal_str = "$"..tostring(player.balance)
	local x, y = get_centered_text_dims(bal_str)
	screen:drawText(bal_str, font, x, y, colors.white)
	--local x, y = get_centered_text_dims(dbg_txt)
	--screen:drawText(dbg_txt, font, x, y+(y/2), colors.lime)
	screen:push(8, 31, 20, 7)
	screen:clear(colors.white)
	screen:drawText("DONE", font, 0, 1, colors.black)
	screen:pop()
	screen:output()
end

function count_and_draw()
	local depositing = true
	local done_btn   = ak:button(1, 31, 20, 38)

	repeat
		draw()
		turtle.suck(64)
		local val = turtle.getItemCount(turtle.getSelectedSlot())
		if val > 0 then
			if turtle.getItemDetail().name == "minecraft:diamond" then
				player.balance = player.balance + val
				empty()
			else
				discard()
			end
		end
		if done_btn.pressed(touch_x, touch_y) then
			depositing = false
		end
	until depositing == false

	screen:clear(bg_color)
	local x, y = get_centered_text_dims("ejecting...")
	screen:drawText("ejecting...", font, x, y, colors.yellow)
	screen:output()
	drive.setDiskLabel(player.name..":"..tostring(player.balance))
	os.sleep(1)
	drive.ejectDisk()
end

function update_touch_xy()
	while true do
		local event = {os.pullEvent("monitor_touch")}
		touch_x = event[3]
		touch_y = event[4]
		os.sleep(0.5)
	end
end

function hotpath()
	local label    = ak:split(drive.getDiskLabel(), ":")
	
	player.name    = label[1]
	player.balance = label[2]

	parallel.waitForAny(
		update_touch_xy,
		count_and_draw
	)
end


init()
while true do
	touch_x = -1
	touch_y = -1
	if not drive.isDiskPresent() then
		idle()
	else
		hotpath()
	end
	os.sleep(0.01)
end
