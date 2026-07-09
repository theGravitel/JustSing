local PaintConfig = require(script.Parent.PaintConfig)

local CharacterRigUtil = {}

function CharacterRigUtil.IsPaintablePartName(partName)
	for _, name in ipairs(PaintConfig.PaintableParts) do
		if name == partName then
			return true
		end
	end
	return false
end

-- Returns the list of BaseParts a brush stroke on `partName` should affect.
-- Only the largest brush size spreads paint to linked/adjacent parts; every
-- other size paints just the targeted brick.
function CharacterRigUtil.GetLinkedParts(character, partName, brushSize)
	local names = { partName }
	if brushSize >= PaintConfig.BrushSizes.Max then
		local links = PaintConfig.PartLinks[partName]
		if links then
			for _, linkedName in ipairs(links) do
				table.insert(names, linkedName)
			end
		end
	end

	local parts = {}
	for _, name in ipairs(names) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end
	return parts
end

return CharacterRigUtil
