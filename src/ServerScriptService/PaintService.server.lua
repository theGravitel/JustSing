-- Validates and applies all paint requests from clients: whole-part
-- recoloring (base coat / large brush) and small color "flecks" (fine
-- detail / small brush, for matching busy textures).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))
local CharacterRigUtil = require(Shared:WaitForChild("CharacterRigUtil"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PaintPartRemote = Remotes:WaitForChild("PaintPart")
local PaintFleckRemote = Remotes:WaitForChild("PaintFleck")

local lastPaintTime = {}

local function withinDebounce(player)
	local now = os.clock()
	local last = lastPaintTime[player]
	if last and now - last < PaintConfig.PaintDebounceSeconds then
		return false
	end
	lastPaintTime[player] = now
	return true
end

local function clampColor(color)
	return Color3.new(math.clamp(color.R, 0, 1), math.clamp(color.G, 0, 1), math.clamp(color.B, 0, 1))
end

local function onPaintPart(player, partName, color, brushSize)
	if typeof(partName) ~= "string" or typeof(color) ~= "Color3" or typeof(brushSize) ~= "number" then
		return
	end
	if not CharacterRigUtil.IsPaintablePartName(partName) then
		return
	end
	if not withinDebounce(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	brushSize = math.clamp(math.floor(brushSize), PaintConfig.BrushSizes.Min, PaintConfig.BrushSizes.Max)
	local color3 = clampColor(color)

	for _, part in ipairs(CharacterRigUtil.GetLinkedParts(character, partName, brushSize)) do
		if part:GetAttribute("Paintable") then
			part.Color = color3
		end
	end
end

local function onPaintFleck(player, partName, color, hitPosition)
	if typeof(partName) ~= "string" or typeof(color) ~= "Color3" or typeof(hitPosition) ~= "Vector3" then
		return
	end
	if not CharacterRigUtil.IsPaintablePartName(partName) then
		return
	end
	if not withinDebounce(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local part = character:FindFirstChild(partName)
	if not part or not part:IsA("BasePart") or not part:GetAttribute("Paintable") then
		return
	end

	-- Basic anti-exploit sanity check: the requested hit has to be roughly
	-- on the surface of the part it claims to paint.
	if (hitPosition - part.Position).Magnitude > part.Size.Magnitude + 2 then
		return
	end

	local flecksFolder = part:FindFirstChild("PaintFlecks")
	if not flecksFolder then
		return
	end

	if #flecksFolder:GetChildren() >= PaintConfig.MaxFlecksPerPart then
		local oldest = flecksFolder:FindFirstChildOfClass("Part")
		if oldest then
			oldest:Destroy()
		end
	end

	local color3 = clampColor(color)
	local sizeRange = PaintConfig.FleckSizeRange
	local size = sizeRange.Min + math.random() * (sizeRange.Max - sizeRange.Min)

	local fleck = Instance.new("Part")
	fleck.Name = "Fleck"
	fleck.Shape = Enum.PartType.Ball
	fleck.Size = Vector3.new(size, size, size)
	fleck.Color = color3
	fleck.Material = Enum.Material.SmoothPlastic
	fleck.CanCollide = false
	fleck.CanQuery = false
	fleck.CastShadow = false
	fleck.Anchored = false
	fleck.CFrame = CFrame.new(hitPosition)
	fleck.Parent = flecksFolder

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = fleck
	weld.Parent = fleck
end

PaintPartRemote.OnServerEvent:Connect(onPaintPart)
PaintFleckRemote.OnServerEvent:Connect(onPaintFleck)
