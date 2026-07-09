-- Crouch / lie down / stretch poses for fitting your painted body into the
-- scenery. Implemented by tweening R6 Motor6D joint offsets directly, so no
-- external animation assets are required for this base.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SetPoseRemote = Remotes:WaitForChild("SetPose")

local TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local defaultC0 = {}
local currentPoseName = "Stand"

local POSES = {
	Stand = {},
	Crouch = {
		RootJoint = CFrame.new(0, -1.1, 0),
		["Left Hip"] = CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(60), 0, 0),
		["Right Hip"] = CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(60), 0, 0),
		["Left Shoulder"] = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(-30), 0, 0),
		["Right Shoulder"] = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(-30), 0, 0),
		Neck = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), 0, 0),
	},
	LieDown = {
		RootJoint = CFrame.new(0, -2, 0.5) * CFrame.Angles(math.rad(-90), 0, 0),
		["Left Hip"] = CFrame.new(-1, -1, 0),
		["Right Hip"] = CFrame.new(1, -1, 0),
		["Left Shoulder"] = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(-80), 0, 0),
		["Right Shoulder"] = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(-80), 0, 0),
		Neck = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(80), 0, 0),
	},
	Stretch = {
		["Left Shoulder"] = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		["Right Shoulder"] = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		["Left Hip"] = CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(-20), 0, 0),
		["Right Hip"] = CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(20), 0, 0),
	},
}

local function findJoint(character, jointName)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Name == jointName then
			return descendant
		end
	end
	return nil
end

local function captureDefaults(character)
	defaultC0 = {}
	for jointName in pairs(POSES.Crouch) do
		local joint = findJoint(character, jointName)
		if joint then
			defaultC0[jointName] = joint.C0
		end
	end
end

local function applyPose(poseName)
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local poseData = POSES[poseName]
	if not poseData then
		return
	end

	currentPoseName = poseName
	-- Disabling physics-driven state lets the tweened joint offsets hold
	-- the pose instead of being fought/reset by walking/jumping states.
	humanoid.PlatformStand = (poseName ~= "Stand")

	for jointName, defaultOffset in pairs(defaultC0) do
		local joint = findJoint(character, jointName)
		if joint then
			local target = poseData[jointName] or defaultOffset
			TweenService:Create(joint, TWEEN_INFO, { C0 = target }):Play()
		end
	end

	SetPoseRemote:FireServer(poseName)
end

local function onCharacterAdded(character)
	character:WaitForChild("Torso", 10)
	captureDefaults(character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local keybinds = PaintConfig.Keybinds.Poses
	if input.KeyCode == keybinds.Stand then
		applyPose("Stand")
	elseif input.KeyCode == keybinds.Crouch then
		applyPose(currentPoseName == "Crouch" and "Stand" or "Crouch")
	elseif input.KeyCode == keybinds.LieDown then
		applyPose(currentPoseName == "LieDown" and "Stand" or "LieDown")
	elseif input.KeyCode == keybinds.Stretch then
		applyPose(currentPoseName == "Stretch" and "Stand" or "Stretch")
	end
end)
