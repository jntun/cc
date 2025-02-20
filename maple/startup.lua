local length = 27

function inspect(length)
	local present, block = turtle.inspect()
	if present and block.name == "minecraft:oak_log" then
		turtle.dig()
	end
	turtle.turnLeft()
	turtle.forward()
	turtle.turnRight()
end

function corner()
	turtle.turnLeft()
	turtle.forward()
	turtle.turnRight()
	turtle.forward()
	turtle.turnRight()
end

while true do
	inspect(length)
	corner()
	inspect(2)
	corner()
	inspect(length)
	corner()
end
