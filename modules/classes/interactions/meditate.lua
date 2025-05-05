local workspot = require("modules/classes/interactions/workspot")

---Class for meditation interaction
---@class meditate : workspot
local meditate = setmetatable({}, { __index = workspot })

function meditate:new(mod, project)
    ---@class meditate
	local o = workspot.new(self, mod, project)

    o.interactionType = "Meditate"
    o.modulePath = "interactions/meditate"
    o.scene = "nif\\quest\\meditate.scene"
    o.skipFact = "nif_skip_meditate"
    o.endEvent = "nif_exit_meditate"
    o.startFactID = 13

    o.name = "Meditate Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Meditation

    setmetatable(o, { __index = self })
   	return o
end

return meditate