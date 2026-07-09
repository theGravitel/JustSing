-- Forces every player into the classic R6 avatar (blocky, single-part limbs)
-- and strips clothing so each body part is a plain, paintable brick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))

Players.AvatarType = Enum.AvatarType.R6

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
	for _, partName in ipairs(PaintConfig.PaintableParts) do
		local part = character:FindFirstChild(partName)
		if part then
			part.Color = PaintConfig.DefaultColor
			part.Material = Enum.Material.SmoothPlastic
			part:SetAttribute("Paintable", true)

			if not part:FindFirstChild("PaintFlecks") then
				local flecksFolder = Instance.new("Folder")
				flecksFolder.Name = "PaintFlecks"
				flecksFolder.Parent = part
			end
		end
	end
end

local function onCharacterAppearanceLoaded(character)
	stripCosmetics(character)
	preparePaintableParts(character)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(onCharacterAppearanceLoaded)
end)
