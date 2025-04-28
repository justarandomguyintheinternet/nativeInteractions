local workspot = require("modules/classes/interactions/workspot")

---Class for bed interaction
---@class bed : workspot
local bed = setmetatable({}, { __index = workspot })

function bed:new(mod, project)
    ---@class bed
	local o = workspot.new(self, mod, project)

    o.interactionType = "Bed"
    o.modulePath = "interactions/bed"
    o.scene = "nif\\quest\\sleep.scene"
    o.skipFact = "nif_skip_bed"
    o.endEvent = "nif_exit_bed"
    o.startFactID = 4

    o.name = "Bed Interaction"
    o.worldIcon = "ChoiceIcons.WaitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.BedOutline

    setmetatable(o, { __index = self })
   	return o
end

return bed