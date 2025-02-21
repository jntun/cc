dofile("ccrepo/lib/ak")
dofile("ccrepo/lib/enclave")
local ledger_db, running

ak.project = "sep"
ledger_db = ak:file("accounts.db")
running = true

function debug(names, balances)
    for _, name in ipairs(names) do print("[name] "..name) end
    for _, bal in ipairs(balances) do print("[balance] "..bal) end
end

function db()
    local names    = {}
    local balances = {}
    local doingNames = true

    local i = 1
    for line in io.lines(ledger_db) do
        if line == "###" then -- Magic indicator to begin reading balance values in the file
            doingNames = false
            i = 1
            goto continue
        end

        if doingNames then
            names[i] = line
        else
            balances[i] = line
        end

        i = i + 1
        ::continue::
    end
    return names, balances
end

function db_verify_can_write()
	local names, balances = db()
	local test_db = io.open(ak:file("accounts_new.db"), "w+")
	for _, name in ipairs(names) do
		test_db:write(name.."\n")
	end
	test_db:write("###\n")
	for _, bal in ipairs(balances) do
		test_db:write(bal.."\n")
	end
	test_db:close()

	local doingNames = true
	local i = 1
	for line in io.lines(ak:file("accounts_new.db")) do
		if line == "###" then
			doingNames = false
			i = 1
			goto pass 
		end

		if doingNames then
			if names[i] ~= line then
				printError("[names]", names[i], line)
				return false
			end
		else
			if balances[i] ~= line then
				printError("[bals]", names[i], line)
				return false
			end
		end

		i = i + 1
		::pass::
	end

	return true
end

function db_save(names, balances)
    if not db_verify_can_write() then
	    error("database file is not safe for writing, aborting db_save().")
	    return
    end
    local ledger = io.open(ledger_db, "w+")
    for _, name in ipairs(names) do
	ledger:write(name.."\n")
    end
    ledger:write("###\n")
    for _, bal in ipairs(balances) do
	ledger:write(bal.."\n")
    end
    ledger:close()
end

function balance_index(user, names, balances)
    for i, name in ipairs(names) do
	    if name == user then
		    return i
	   end
   end
end


function balance_set(user, amount, names, balances)
    local name_index = nil
    amount = tonumber(amount)
    if amount == nil then
	    return false
    end
    for i, name in ipairs(names) do
	if name == user then
	    name_index = i
	end
    end
    if name_index == nil then
	    return false
    end

    balances[name_index] = amount
    db_save(names, balances)
    return true
end

function name_set(user, new_user, names, balances)
    local index = nil
    for i, name in ipairs(names) do
	if name == user then
	    index = i
	end
    end

    names[index] = new_user
    db_save(names, balances)
end

function create_user(user, balance, names, balances)
    local count = 0
    for _ in pairs(names) do count = count + 1 end
    names[count+1] = user
    balances[count+1] = balance
    db_save(names, balances)
end

function balance_get(user, names, balances)
    local index = nil
    for i, name in ipairs(names) do
	if name == user then
	    index = i
	end
    end
    return balances[index]
end

local names, bals = db()
--print(balance_get("dr cope", names, bals))
--balance_set("dr cope", 1339, names, bals)
--print(balance_get("dr cope", names, bals))

ENC.modem.open(ENC_CHAN_MAIN)
while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    print("[debug]", channel, replyChannel, distance, "[".. message.."]")
    if channel == ENC_CHAN_MAIN then
	local msg = ak:split(message, ":")
	local op = msg[1]
	if msg[2] == nil then -- nil data check
		goto pass
	end

	if op == ENC_OP_BALANCE_GET then
		local bal = balance_get(msg[2], db())
		if bal == nil then
			printError("OP_BALANCE_GET found nil balance for user: "..msg[2])
			ENC:reply(ENC_OP_BALANCE_GET, -1)
			goto pass
		end
		ENC:reply(ENC_OP_BALANCE_GET, bal)
	elseif op == ENC_OP_BALANCE_SET then
		local user = msg[2]
		local amount = msg[3]
		if amount == nil then
			printError("OP_BALANCE_SET was given empty amount. Likely cheating...")
			goto pass
		end
		if not balance_set(user, amount, db()) then
			printError("balance_set() failed. user: "..user.." amount:"..amount)
			goto pass
		end
	elseif op == ENC_OP_NEW_USER then
		local username = msg[2]
		local bal      = msg[3]
		if bal == nil then
			bal = 0
		end
		create_user(username, bal, db())
	elseif op == ENC_OP_HEARTBEAT then
		ENC:reply(ENC_OP_HEARTBEAT, "heart")
	end
    end

    ::pass::
end
