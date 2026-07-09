-- Minimal hide-and-seek round loop: intermission -> hiding -> seeking ->
-- round end. One random seeker, everyone else hides. This is a base loop
-- meant to be expanded (scoring, team colors, multiple seekers, etc.).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundStateChanged = Remotes:WaitForChild("RoundStateChanged")

local INTERMISSION_TIME = 15
local HIDING_TIME = 20
local SEEKING_TIME = 90

local function getAlivePlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			table.insert(list, player)
		end
	end
	return list
end

local function announce(phase, duration, extra)
	RoundStateChanged:FireAllClients(phase, duration, extra)
end

local function runRound()
	local players = getAlivePlayers()
	if #players < 2 then
		announce("WaitingForPlayers", 0)
		task.wait(5)
		return
	end

	announce("Intermission", INTERMISSION_TIME)
	task.wait(INTERMISSION_TIME)

	players = getAlivePlayers()
	if #players < 2 then
		return
	end

	local seeker = players[math.random(1, #players)]
	local hiders = {}
	for _, player in ipairs(players) do
		if player ~= seeker then
			table.insert(hiders, player)
		end
	end

	announce("Hiding", HIDING_TIME, seeker.Name)
	task.wait(HIDING_TIME)

	announce("Seeking", SEEKING_TIME, seeker.Name)

	local caught = {}
	local connections = {}
	for _, hider in ipairs(hiders) do
		local character = hider.Character
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			connections[hider] = humanoidRootPart.Touched:Connect(function(hitPart)
				local otherCharacter = hitPart:FindFirstAncestorOfClass("Model")
				if otherCharacter and seeker.Character and otherCharacter == seeker.Character then
					caught[hider] = true
				end
			end)
		end
	end

	local roundEndTime = os.clock() + SEEKING_TIME
	while os.clock() < roundEndTime do
		local remaining = 0
		for _, hider in ipairs(hiders) do
			if not caught[hider] then
				remaining += 1
			end
		end
		if remaining == 0 then
			break
		end
		task.wait(1)
	end

	for _, connection in pairs(connections) do
		connection:Disconnect()
	end

	announce("RoundEnd", 5, seeker.Name)
	task.wait(5)
end

task.spawn(function()
	while true do
		local ok, err = pcall(runRound)
		if not ok then
			warn("[RoundService] round error:", err)
			task.wait(3)
		end
	end
end)
