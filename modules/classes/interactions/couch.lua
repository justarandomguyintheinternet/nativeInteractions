local workspot = require("modules/classes/interactions/workspot")

---Class for couch interaction
---@class couch : workspot
local couch = setmetatable({}, { __index = workspot })

function couch:new(mod, project)
    ---@class couch
	local o = workspot.new(self, mod, project)

    o.interactionType = "Couch"
    o.modulePath = "interactions/couch"
    o.scene = "quest\\couch.scene"
    o.skipFact = "nif_skip_couch"
    o.endEvent = "nif_exit_couch"
    o.startFactID = 2

    o.name = "Couch Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Sofa

    setmetatable(o, { __index = self })
   	return o
end

return couch