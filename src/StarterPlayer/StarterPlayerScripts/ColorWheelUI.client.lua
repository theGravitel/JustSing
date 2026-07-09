-- Color picker panel: a hue strip + saturation/value square (the standard,
-- fully-explorable HSV "color wheel" control), plus save-able palette
-- swatches synced to the server.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))
local PaintState = require(Shared:WaitForChild("PaintState"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SavePaletteRemote = Remotes:WaitForChild("SavePalette")
local GetPaletteRemote = Remotes:WaitForChild("GetPalette")

local currentHue = 0

-- === Root GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorPickerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(1, 1)
toggleButton.Position = UDim2.new(1, -16, 1, -16)
toggleButton.Size = UDim2.new(0, 120, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.Text = "Colors"
toggleButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -16, 1, -68)
panel.Size = UDim2.new(0, 240, 0, 400)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = panel

toggleButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

-- === Saturation/Value square ===
local svSquare = Instance.new("Frame")
svSquare.Name = "SVSquare"
svSquare.LayoutOrder = 1
svSquare.Size = UDim2.new(0, 216, 0, 150)
svSquare.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
svSquare.Active = true
svSquare.ClipsDescendants = true
svSquare.Parent = panel

local svWhiteOverlay = Instance.new("Frame")
svWhiteOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
svWhiteOverlay.BorderSizePixel = 0
svWhiteOverlay.Size = UDim2.new(1, 0, 1, 0)
svWhiteOverlay.Parent = svSquare

local svWhiteGradient = Instance.new("UIGradient")
svWhiteGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
svWhiteGradient.Rotation = 0
svWhiteGradient.Parent = svWhiteOverlay

local svBlackOverlay = Instance.new("Frame")
svBlackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
svBlackOverlay.BorderSizePixel = 0
svBlackOverlay.Size = UDim2.new(1, 0, 1, 0)
svBlackOverlay.Parent = svSquare

local svBlackGradient = Instance.new("UIGradient")
svBlackGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})
svBlackGradient.Rotation = 90
svBlackGradient.Parent = svBlackOverlay

local svCursor = Instance.new("Frame")
svCursor.Name = "Cursor"
svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
svCursor.Size = UDim2.new(0, 12, 0, 12)
svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
svCursor.BorderSizePixel = 0
svCursor.ZIndex = 5
svCursor.Position = UDim2.new(0, 0, 0, 0)
svCursor.Parent = svSquare

local svCursorCorner = Instance.new("UICorner")
svCursorCorner.CornerRadius = UDim.new(1, 0)
svCursorCorner.Parent = svCursor

local svCursorStroke = Instance.new("UIStroke")
svCursorStroke.Thickness = 2
svCursorStroke.Color = Color3.new(0, 0, 0)
svCursorStroke.Parent = svCursor

-- === Hue strip ===
local hueStrip = Instance.new("Frame")
hueStrip.Name = "HueStrip"
hueStrip.LayoutOrder = 2
hueStrip.Size = UDim2.new(0, 216, 0, 24)
hueStrip.BackgroundColor3 = Color3.new(1, 1, 1)
hueStrip.Active = true
hueStrip.Parent = panel

local hueGradient = Instance.new("UIGradient")
hueGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
	ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
	ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})
hueGradient.Parent = hueStrip

local hueCursor = Instance.new("Frame")
hueCursor.Name = "Cursor"
hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
hueCursor.Size = UDim2.new(0, 6, 1, 4)
hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
hueCursor.BorderSizePixel = 0
hueCursor.ZIndex = 5
hueCursor.Position = UDim2.new(0, 0, 0.5, 0)
hueCursor.Parent = hueStrip

local hueCursorStroke = Instance.new("UIStroke")
hueCursorStroke.Thickness = 2
hueCursorStroke.Color = Color3.new(0, 0, 0)
hueCursorStroke.Parent = hueCursor

-- === Preview swatch ===
local preview = Instance.new("Frame")
preview.Name = "Preview"
preview.LayoutOrder = 3
preview.Size = UDim2.new(0, 216, 0, 28)
preview.BackgroundColor3 = PaintState.HeldColor
preview.Parent = panel

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 6)
previewCorner.Parent = preview

-- === Palette row ===
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.LayoutOrder = 4
hint.Size = UDim2.new(0, 216, 0, 32)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.new(1, 1, 1)
hint.TextWrapped = true
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.Text = "Click: select swatch  |  Shift+Click: save current color"
hint.Parent = panel

local paletteContainer = Instance.new("Frame")
paletteContainer.Name = "Palette"
paletteContainer.LayoutOrder = 5
paletteContainer.Size = UDim2.new(0, 216, 0, 60)
paletteContainer.BackgroundTransparency = 1
paletteContainer.Parent = panel

local paletteLayout = Instance.new("UIGridLayout")
paletteLayout.CellSize = UDim2.new(0, 36, 0, 26)
paletteLayout.CellPadding = UDim2.new(0, 4, 0, 4)
paletteLayout.Parent = paletteContainer

local swatchButtons = {}
local savedColors = {}

local function refreshSwatchVisuals()
	for i, button in ipairs(swatchButtons) do
		local color = savedColors[i]
		button.BackgroundColor3 = color or Color3.fromRGB(60, 60, 60)
		button.Text = color and "" or tostring(i)
	end
end

local function selectHeldColor(color)
	PaintState.HeldColor = color
	preview.BackgroundColor3 = color

	local h, s, v = Color3.toHSV(color)
	currentHue = h
	svSquare.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
	hueCursor.Position = UDim2.new(currentHue, 0, 0.5, 0)
	svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
end

for i = 1, PaintConfig.MaxPaletteSlots do
	local button = Instance.new("TextButton")
	button.Name = "Swatch" .. i
	button.LayoutOrder = i
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.Text = tostring(i)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.Parent = paletteContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		if shiftHeld then
			savedColors[i] = PaintState.HeldColor
			refreshSwatchVisuals()
			SavePaletteRemote:InvokeServer(savedColors)
		elseif savedColors[i] then
			selectHeldColor(savedColors[i])
		end
	end)

	swatchButtons[i] = button
end

task.spawn(function()
	local ok, loaded = pcall(function()
		return GetPaletteRemote:InvokeServer()
	end)
	if ok and typeof(loaded) == "table" then
		for i, color in pairs(loaded) do
			if typeof(i) == "number" and i <= PaintConfig.MaxPaletteSlots then
				savedColors[i] = color
			end
		end
		refreshSwatchVisuals()
	end
end)

-- === Drag handling for hue strip / SV square ===
local draggingHue = false
local draggingSV = false

local function updateHue(inputPositionX)
	local relative = math.clamp((inputPositionX - hueStrip.AbsolutePosition.X) / hueStrip.AbsoluteSize.X, 0, 1)
	currentHue = relative
	hueCursor.Position = UDim2.new(relative, 0, 0.5, 0)
	svSquare.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)

	local _, s, v = Color3.toHSV(PaintState.HeldColor)
	local newColor = Color3.fromHSV(currentHue, s, v)
	PaintState.HeldColor = newColor
	preview.BackgroundColor3 = newColor
end

local function updateSV(inputPositionX, inputPositionY)
	local relX = math.clamp((inputPositionX - svSquare.AbsolutePosition.X) / svSquare.AbsoluteSize.X, 0, 1)
	local relY = math.clamp((inputPositionY - svSquare.AbsolutePosition.Y) / svSquare.AbsoluteSize.Y, 0, 1)
	svCursor.Position = UDim2.new(relX, 0, relY, 0)

	local newColor = Color3.fromHSV(currentHue, relX, 1 - relY)
	PaintState.HeldColor = newColor
	preview.BackgroundColor3 = newColor
end

hueStrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingHue = true
		updateHue(input.Position.X)
	end
end)

svSquare.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSV = true
		updateSV(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if draggingHue then
		updateHue(input.Position.X)
	elseif draggingSV then
		updateSV(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingHue = false
		draggingSV = false
	end
end)
