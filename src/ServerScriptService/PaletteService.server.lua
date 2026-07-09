-- Persists each player's saved color palette (swatch slots) to DataStore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PaintConfig = require(Shared:WaitForChild("PaintConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SavePaletteRemote = Remotes:WaitForChild("SavePalette")
local GetPaletteRemote = Remotes:WaitForChild("GetPalette")

local paletteStore = DataStoreService:GetDataStore("MecchaChameleon_Palettes_v1")

local function serializeColor(color)
	return { color.R, color.G, color.B }
end

local function deserializeColor(entry)
	if typeof(entry) ~= "table" or #entry ~= 3 then
		return nil
	end
	return Color3.new(math.clamp(entry[1], 0, 1), math.clamp(entry[2], 0, 1), math.clamp(entry[3], 0, 1))
end

local function onSavePalette(player, colors)
	if typeof(colors) ~= "table" then
		return false
	end

	local serialized = {}
	for i = 1, PaintConfig.MaxPaletteSlots do
		if typeof(colors[i]) == "Color3" then
			serialized[i] = serializeColor(colors[i])
		end
	end

	local key = "Player_" .. player.UserId
	local success = pcall(function()
		paletteStore:SetAsync(key, serialized)
	end)
	return success
end

local function onGetPalette(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return paletteStore:GetAsync(key)
	end)

	if not success or typeof(data) ~= "table" then
		return {}
	end

	local colors = {}
	for i, entry in ipairs(data) do
		local color = deserializeColor(entry)
		if color then
			colors[i] = color
		end
	end
	return colors
end

SavePaletteRemote.OnServerInvoke = onSavePalette
GetPaletteRemote.OnServerInvoke = onGetPalette
