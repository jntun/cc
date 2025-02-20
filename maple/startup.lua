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
	turtle.right()
	turtle.forward()
	turtle.right()
end

while true do
	inspect(length)
	corner()
	inspect(2)
	corner()
	inspect(length)
	corner()
end
