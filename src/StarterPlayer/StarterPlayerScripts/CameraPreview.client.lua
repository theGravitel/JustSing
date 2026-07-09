-- "Hunter's perspective": press P to pull the camera back into a slow orbit
-- around your own character so you can check how your camouflage reads
-- from a distance, the way a seeker would see you.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))

local HUNTER_DISTANCE = 18
local HUNTER_HEIGHT = 6
local ORBIT_SPEED = 0.3

local hunterViewEnabled = false
local orbitAngle = 0
local savedCameraType = Enum.CameraType.Custom

local function getRootPart()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function updateHunterCamera(deltaTime)
	local camera = Workspace.CurrentCamera
	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	orbitAngle += deltaTime * ORBIT_SPEED
	local offset = Vector3.new(math.cos(orbitAngle), 0, math.sin(orbitAngle)) * HUNTER_DISTANCE
	local cameraPosition = rootPart.Position + offset + Vector3.new(0, HUNTER_HEIGHT, 0)
	camera.CFrame = CFrame.lookAt(cameraPosition, rootPart.Position)
end

local function toggleHunterView()
	local camera = Workspace.CurrentCamera
	hunterViewEnabled = not hunterViewEnabled

	if hunterViewEnabled then
		savedCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
	else
		camera.CameraType = savedCameraType
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == PaintConfig.Keybinds.ToggleHunterCamera then
		toggleHunterView()
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if hunterViewEnabled then
		updateHunterCamera(deltaTime)
	end
end)
