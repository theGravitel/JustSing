-- Mutable client-side paint state shared between PaintController and
-- ColorWheelUI. Both LocalScripts run in the same client and requiring the
-- same ModuleScript returns the same cached table, so this works as a
-- simple in-process store without needing BindableEvents.

local PaintConfig = require(script.Parent.PaintConfig)

local PaintState = {
	HeldColor = PaintConfig.DefaultColor,
	BrushSize = PaintConfig.BrushSizes.Default,
}

return PaintState
