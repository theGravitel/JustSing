-- Shared tunables and keybinds for the paint/camouflage system.
-- Required by both server and client scripts.

local PaintConfig = {}

PaintConfig.Keybinds = {
	ToggleColorPicker = Enum.KeyCode.Space,
	TogglePaintMode = Enum.KeyCode.F,
	ResizeBrush = Enum.UserInputType.MouseButton2,
	ApplyPaint = Enum.UserInputType.MouseButton1,
	ToggleHunterCamera = Enum.KeyCode.P,
	Poses = {
		Stand = Enum.KeyCode.V,
		Crouch = Enum.KeyCode.C,
		LieDown = Enum.KeyCode.Z,
		Stretch = Enum.KeyCode.X,
	},
}

-- R6 body parts: every one of these is a single BasePart, so recoloring it
-- is a full "brick" repaint. This is why CharacterSetup forces R6 avatars.
PaintConfig.PaintableParts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

-- Which parts a max-size brush spreads to when you paint one of them.
PaintConfig.PartLinks = {
	Torso = { "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
	Head = { "Torso" },
	["Left Arm"] = { "Torso" },
	["Right Arm"] = { "Torso" },
	["Left Leg"] = { "Torso" },
	["Right Leg"] = { "Torso" },
}

PaintConfig.BrushSizes = {
	Min = 1,
	Max = 5,
	Default = 3,
	-- At or below this size, painting drops small color "flecks" instead of
	-- recoloring the whole brick (used for matching busy/detailed textures).
	DetailThreshold = 2,
}

PaintConfig.MaxFlecksPerPart = 60
PaintConfig.FleckSizeRange = { Min = 0.12, Max = 0.28 }
PaintConfig.MaxPaintDistance = 20
PaintConfig.PaintDebounceSeconds = 0.05

PaintConfig.MaxPaletteSlots = 10
PaintConfig.DefaultColor = Color3.new(1, 1, 1)

return PaintConfig
