local workspot = require("modules/classes/interactions/workspot")

---Class for chair interaction
---@class chair : workspot
local chair = setmetatable({}, { __index = workspot })

function chair:new(mod, project)
    ---@class chair
	local o = workspot.new(self, mod, project)

    o.interactionType = "Chair"
    o.modulePath = "interactions/chair"
    o.scene = "nif\\quest\\sit.scene"
    o.skipFact = "nif_skip_sit"
    o.endEvent = "nif_exit_sit"
    o.startFactID = 15

    o.name = "Chair Interaction"
    o.worldIcon = "ChoiceIcons.WaitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.ChairRolling

    setmetatable(o, { __index = self })
   	return o
end

return chair