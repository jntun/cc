dofile("ccrepo/lib/ak")
dofile("ccrepo/lib/enclave")

ak.project = "ed"

local user = "dr cope"

ENC:heartbeat()
function balance()
	local bal = ENC:balance_get(user)
	if bal == nil then
		print("failed to get bal for "..user)
		return
	end
	print(bal)
end

balance()
ENC:balance_set(user, 420)
balance()
