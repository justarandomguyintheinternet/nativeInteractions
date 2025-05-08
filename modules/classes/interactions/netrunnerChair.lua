local workspot = require("modules/classes/interactions/workspot")

---Class for netrunner chair interaction
---@class netrunnerChair : workspot
local netrunnerChair = setmetatable({}, { __index = workspot })

function netrunnerChair:new(mod, project)
    ---@class netrunnerChair
	local o = workspot.new(self, mod, project)

    o.interactionType = "Netrunner Chair"
    o.modulePath = "interactions/netrunnerChair"
    o.scene = "nif\\quest\\netrunner_chair.scene"
    o.skipFact = "nif_skip_netrunner_chair"
    o.endEvent = "nif_exit_netrunner_chair"
    o.startFactID = 17

    o.name = "Netrunner Chair Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.ChairSchool

    setmetatable(o, { __index = self })
   	return o
end

return netrunnerChair