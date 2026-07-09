-- Core paint input: spacebar eyedropper (copy environment color onto your
-- whole body), F to enter Paint Mode, right-drag to resize the brush, and
-- left-click to paint the aimed limb (solid recolor or fine detail flecks
-- depending on brush size).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))
local PaintState = require(Shared:WaitForChild("PaintState"))
local CharacterRigUtil = require(Shared:WaitForChild("CharacterRigUtil"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PaintPartRemote = Remotes:WaitForChild("PaintPart")
local PaintFleckRemote = Remotes:WaitForChild("PaintFleck")

local paintModeEnabled = false
local isResizingBrush = false
local resizeStartY = 0
local resizeStartSize = PaintConfig.BrushSizes.Default

-- === HUD: paint mode label + brush reticle ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaintHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local modeLabel = Instance.new("TextLabel")
modeLabel.Name = "ModeLabel"
modeLabel.AnchorPoint = Vector2.new(0.5, 0)
modeLabel.Position = UDim2.new(0.5, 0, 0, 12)
modeLabel.Size = UDim2.new(0, 260, 0, 32)
modeLabel.BackgroundTransparency = 0.4
modeLabel.BackgroundColor3 = Color3.new(0, 0, 0)
modeLabel.TextColor3 = Color3.new(1, 1, 1)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.Text = "Paint Mode: OFF  (F)"
modeLabel.Parent = screenGui

local reticle = Instance.new("Frame")
reticle.Name = "BrushReticle"
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.BackgroundTransparency = 1
reticle.BorderSizePixel = 0
reticle.Visible = false
reticle.Size = UDim2.new(0, 24, 0, 24)
reticle.Parent = screenGui

local reticleCorner = Instance.new("UICorner")
reticleCorner.CornerRadius = UDim.new(1, 0)
reticleCorner.Parent = reticle

local reticleStroke = Instance.new("UIStroke")
reticleStroke.Thickness = 2
reticleStroke.Color = Color3.new(1, 1, 1)
reticleStroke.Parent = reticle

local function updateModeLabel()
	modeLabel.Text = paintModeEnabled
		and ("Paint Mode: ON  (F) | Brush: " .. PaintState.BrushSize)
		or "Paint Mode: OFF  (F)"
end

local function brushSizeToPixels(size)
	local t = (size - PaintConfig.BrushSizes.Min) / (PaintConfig.BrushSizes.Max - PaintConfig.BrushSizes.Min)
	return 12 + t * 60
end

-- === Raycasting helpers ===
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

-- === Spacebar: eyedrop the environment and base-coat the whole body ===
local function useEyedropper()
	local result = raycastEnvironment()
	if not result or not result.Instance or not result.Instance:IsA("BasePart") then
		return
	end

	local color = result.Instance.Color
	PaintState.HeldColor = color

	for _, partName in ipairs(PaintConfig.PaintableParts) do
		PaintPartRemote:FireServer(partName, color, PaintConfig.BrushSizes.Max)
	end
end

-- === Paint Mode: left click paints the aimed limb on yourself ===
local function applyPaint()
	local result = raycastOwnCharacter()
	if not result or not result.Instance or not result.Instance:IsA("BasePart") then
		return
	end

	local part = result.Instance
	if not CharacterRigUtil.IsPaintablePartName(part.Name) then
		return
	end

	local color = PaintState.HeldColor
	local brushSize = PaintState.BrushSize

	if brushSize <= PaintConfig.BrushSizes.DetailThreshold then
		PaintFleckRemote:FireServer(part.Name, color, result.Position)
	else
		PaintPartRemote:FireServer(part.Name, color, brushSize)
	end
end

-- === Input ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == PaintConfig.Keybinds.ToggleColorPicker then
		useEyedropper()
	elseif input.KeyCode == PaintConfig.Keybinds.TogglePaintMode then
		paintModeEnabled = not paintModeEnabled
		reticle.Visible = paintModeEnabled
		updateModeLabel()
	elseif paintModeEnabled and input.UserInputType == PaintConfig.Keybinds.ResizeBrush then
		isResizingBrush = true
		resizeStartY = UserInputService:GetMouseLocation().Y
		resizeStartSize = PaintState.BrushSize
	elseif paintModeEnabled and input.UserInputType == PaintConfig.Keybinds.ApplyPaint then
		applyPaint()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isResizingBrush and input.UserInputType == Enum.UserInputType.MouseMovement then
		local currentY = UserInputService:GetMouseLocation().Y
		local delta = resizeStartY - currentY
		local newSize = resizeStartSize + math.floor(delta / 25)
		PaintState.BrushSize = math.clamp(newSize, PaintConfig.BrushSizes.Min, PaintConfig.BrushSizes.Max)
		updateModeLabel()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == PaintConfig.Keybinds.ResizeBrush then
		isResizingBrush = false
	end
end)

RunService.RenderStepped:Connect(function()
	if paintModeEnabled then
		local mouseLocation = UserInputService:GetMouseLocation()
		reticle.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
		local pixelSize = brushSizeToPixels(PaintState.BrushSize)
		reticle.Size = UDim2.new(0, pixelSize, 0, pixelSize)
	end
end)

updateModeLabel()
