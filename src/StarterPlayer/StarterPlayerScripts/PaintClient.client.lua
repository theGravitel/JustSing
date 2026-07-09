-- PaintClient (LocalScript, in StarterPlayerScripts)
--
-- All client-side input and UI for the paint system: a row of color
-- swatches to pick a color, Space to eyedrop a color off anything you're
-- looking at (paints your whole body), and F + left-click to paint
-- individual limbs on yourself.
--
-- Watch the Output window (View > Output) for [PaintClient] messages.

print("[PaintClient] script started")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- WaitForChild with a timeout so a missing remote prints a clear error
-- instead of freezing this script forever with no explanation.
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotes then
	warn("[PaintClient] ReplicatedStorage.Remotes never appeared after 10s - is PaintServer running in ServerScriptService?")
	return
end
print("[PaintClient] found ReplicatedStorage.Remotes")

local paintPart = remotes:WaitForChild("PaintPart", 10)
if not paintPart then
	warn("[PaintClient] Remotes.PaintPart never appeared after 10s - check PaintServer's Output for errors")
	return
end
print("[PaintClient] found Remotes.PaintPart, setting up UI and input")

local PAINTABLE_PARTS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local PRESET_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 165, 0),
	Color3.fromRGB(255, 230, 0),
	Color3.fromRGB(0, 180, 0),
	Color3.fromRGB(0, 120, 255),
	Color3.fromRGB(140, 0, 200),
	Color3.fromRGB(120, 80, 40),
	Color3.fromRGB(150, 150, 150),
}

local heldColor = Color3.new(1, 1, 1)
local paintModeEnabled = false

local function isPaintablePartName(name)
	for _, partName in ipairs(PAINTABLE_PARTS) do
		if partName == name then
			return true
		end
	end
	return false
end

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaintHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local modeLabel = Instance.new("TextLabel")
modeLabel.Name = "ModeLabel"
modeLabel.AnchorPoint = Vector2.new(0.5, 0)
modeLabel.Position = UDim2.new(0.5, 0, 0, 12)
modeLabel.Size = UDim2.new(0, 400, 0, 32)
modeLabel.BackgroundColor3 = Color3.new(0, 0, 0)
modeLabel.BackgroundTransparency = 0.4
modeLabel.TextColor3 = Color3.new(1, 1, 1)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.Parent = screenGui

local function updateModeLabel()
	if paintModeEnabled then
		modeLabel.Text = "Paint Mode: ON (F)  |  Left-click your body to paint a limb"
	else
		modeLabel.Text = "Paint Mode: OFF (F)  |  Space = eyedrop color from what you're looking at"
	end
end
updateModeLabel()

local swatchRow = Instance.new("Frame")
swatchRow.Name = "Swatches"
swatchRow.AnchorPoint = Vector2.new(0.5, 1)
swatchRow.Position = UDim2.new(0.5, 0, 1, -20)
swatchRow.Size = UDim2.new(0, #PRESET_COLORS * 44, 0, 40)
swatchRow.BackgroundTransparency = 1
swatchRow.Parent = screenGui

local swatchLayout = Instance.new("UIListLayout")
swatchLayout.FillDirection = Enum.FillDirection.Horizontal
swatchLayout.Padding = UDim.new(0, 4)
swatchLayout.Parent = swatchRow

for i, color in ipairs(PRESET_COLORS) do
	local button = Instance.new("TextButton")
	button.Name = "Swatch" .. i
	button.LayoutOrder = i
	button.Size = UDim2.new(0, 40, 0, 40)
	button.BackgroundColor3 = color
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = swatchRow

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = button

	button.MouseButton1Click:Connect(function()
		heldColor = color
		print("[PaintClient] held color set from swatch:", color)
	end)
end

-- === Raycasting ===
local function getMouseRay()
	local camera = Workspace.CurrentCamera
	local mouseLocation = UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
end

local function raycastEnvironment()
	local character = LocalPlayer.Character
	local ray = getMouseRay()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and { character } or {}
	return Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
end

local function raycastOwnCharacter()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	local ray = getMouseRay()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { character }
	return Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
end

-- === Spacebar: eyedrop a color from whatever you're aiming at ===
local function useEyedropper()
	local result = raycastEnvironment()
	if not result or not result.Instance or not result.Instance:IsA("BasePart") then
		print("[PaintClient] eyedropper: no BasePart under the cursor")
		return
	end

	heldColor = result.Instance.Color
	print("[PaintClient] eyedropper picked up", heldColor, "from", result.Instance:GetFullName())

	for _, partName in ipairs(PAINTABLE_PARTS) do
		paintPart:FireServer(partName, heldColor)
	end
end

-- === Paint Mode + left click: paint the limb you're aiming at ===
local function applyPaint()
	local result = raycastOwnCharacter()
	if not result or not result.Instance or not result.Instance:IsA("BasePart") then
		print("[PaintClient] paint click: not aiming at your own character")
		return
	end

	if not isPaintablePartName(result.Instance.Name) then
		print("[PaintClient] paint click: hit a non-paintable part:", result.Instance.Name)
		return
	end

	print("[PaintClient] painting", result.Instance.Name, "with", heldColor)
	paintPart:FireServer(result.Instance.Name, heldColor)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Space then
		useEyedropper()
	elseif input.KeyCode == Enum.KeyCode.F then
		paintModeEnabled = not paintModeEnabled
		updateModeLabel()
		print("[PaintClient] paint mode is now", paintModeEnabled)
	elseif paintModeEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		applyPaint()
	end
end)

print("[PaintClient] ready - Space to eyedrop, F to toggle paint mode, click swatches to pick a color")
