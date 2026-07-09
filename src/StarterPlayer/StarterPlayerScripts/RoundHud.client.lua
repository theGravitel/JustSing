-- Displays the current hide-and-seek round phase and countdown broadcast
-- by RoundService.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundStateChanged = Remotes:WaitForChild("RoundStateChanged")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 48)
label.Size = UDim2.new(0, 320, 0, 40)
label.BackgroundTransparency = 0.4
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.Text = ""
label.Parent = screenGui

local PHASE_TEXT = {
	WaitingForPlayers = "Waiting for more players...",
	Intermission = "Next round starting in %ds",
	Hiding = "Hide! %s is getting ready to seek (%ds)",
	Seeking = "%s is seeking! (%ds)",
	RoundEnd = "Round over!",
}

local remainingTime = 0
local currentPhase = nil
local seekerName = nil

RoundStateChanged.OnClientEvent:Connect(function(phase, duration, extra)
	currentPhase = phase
	remainingTime = duration or 0
	seekerName = extra
end)

RunService.Heartbeat:Connect(function(deltaTime)
	if not currentPhase then
		return
	end
	remainingTime = math.max(0, remainingTime - deltaTime)

	local template = PHASE_TEXT[currentPhase] or currentPhase
	if currentPhase == "Hiding" or currentPhase == "Seeking" then
		label.Text = string.format(template, seekerName or "The seeker", math.ceil(remainingTime))
	elseif currentPhase == "Intermission" then
		label.Text = string.format(template, math.ceil(remainingTime))
	else
		label.Text = template
	end
end)
