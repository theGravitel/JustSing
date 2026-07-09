-- PaintServer (Script, in ServerScriptService)
--
-- Everything the paint system needs on the server: forces blocky R6
-- characters, strips clothing so the bricks show, and applies paint
-- requests from clients. It creates its own Remotes/PaintPart instance if
-- one doesn't already exist, so a missing manual setup step in Studio
-- can't silently break the client scripts.
--
-- Watch the Output window (View > Output) for [PaintServer] messages.

print("[PaintServer] script started")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classic blocky avatar: Head, Torso, Left/Right Arm, Left/Right Leg are
-- each a single BasePart, so every limb is directly paintable.
Players.AvatarType = Enum.AvatarType.R6

local PAINTABLE_PARTS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local function isPaintablePartName(name)
	for _, partName in ipairs(PAINTABLE_PARTS) do
		if partName == name then
			return true
		end
	end
	return false
end

-- === Remotes: create them if they aren't already there ===
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	print("[PaintServer] ReplicatedStorage.Remotes was missing, created it")
else
	print("[PaintServer] found existing ReplicatedStorage.Remotes")
end

local paintPart = remotes:FindFirstChild("PaintPart")
if not paintPart then
	paintPart = Instance.new("RemoteEvent")
	paintPart.Name = "PaintPart"
	paintPart.Parent = remotes
	print("[PaintServer] Remotes.PaintPart was missing, created it")
else
	print("[PaintServer] found existing Remotes.PaintPart")
end

-- === Character setup ===
local function stripCosmetics(character)
	for _, item in ipairs(character:GetChildren()) do
		if
			item:IsA("Shirt")
			or item:IsA("Pants")
			or item:IsA("ShirtGraphic")
			or item:IsA("Accessory")
			or item:IsA("Accoutrement")
		then
			item:Destroy()
		end
	end
end

local function preparePaintableParts(character)
	for _, partName in ipairs(PAINTABLE_PARTS) do
		local part = character:FindFirstChild(partName)
		if part then
			part.Color = Color3.new(1, 1, 1)
			part.Material = Enum.Material.SmoothPlastic
			part:SetAttribute("Paintable", true)
		else
			warn("[PaintServer] expected part not found on character:", partName)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	print("[PaintServer] player joined:", player.Name)
	player.CharacterAppearanceLoaded:Connect(function(character)
		print("[PaintServer] appearance loaded for", player.Name, "- prepping paintable parts")
		stripCosmetics(character)
		preparePaintableParts(character)
		print("[PaintServer]", player.Name, "is ready to paint")
	end)
end)

-- === Handle paint requests ===
paintPart.OnServerEvent:Connect(function(player, partName, color)
	print("[PaintServer] paint request from", player.Name, "-> part:", partName, "color:", color)

	if typeof(partName) ~= "string" or typeof(color) ~= "Color3" then
		warn("[PaintServer] rejected malformed paint request from", player.Name)
		return
	end

	if not isPaintablePartName(partName) then
		warn("[PaintServer] rejected paint request for non-paintable part:", partName)
		return
	end

	local character = player.Character
	if not character then
		warn("[PaintServer] no character for", player.Name, "- can't paint")
		return
	end

	local part = character:FindFirstChild(partName)
	if not part then
		warn("[PaintServer] character has no part named", partName)
		return
	end

	part.Color = Color3.new(math.clamp(color.R, 0, 1), math.clamp(color.G, 0, 1), math.clamp(color.B, 0, 1))
	print("[PaintServer] painted", partName, "for", player.Name)
end)

print("[PaintServer] ready and listening for paint requests")
