local interaction = require("modules/classes/interaction")

---Class for dance interaction
---@class dance : interaction
local dance = setmetatable({}, { __index = interaction })

function dance:new(mod, project)
	local o = interaction.new(self, mod, project)

    o.interactionType = "Dance"
    o.modulePath = "interactions/dance"
    o.scene = "nif\\quest\\dance.scene"
    o.skipFact = "nif_skip_dance"
    o.endEvent = "nif_exit_dance"
    o.startFactID = 14

    o.name = "Dance Interaction"
    o.worldIcon = "ChoiceIcons.DanceIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.HumanFemaleDance

    setmetatable(o, { __index = self })
   	return o
end

return dance