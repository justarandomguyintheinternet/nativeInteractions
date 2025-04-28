local interaction = require("modules/classes/interaction")

---Class for wardrobe interaction
---@class wardrobe : interaction
local wardrobe = setmetatable({}, { __index = interaction })

function wardrobe:new(mod, project)
	local o = interaction.new(self, mod, project)

    o.interactionType = "Wardrobe"
    o.modulePath = "interactions/wardrobe"
    o.scene = "nif\\quest\\wardrobe.scene"
    o.skipFact = "nif_skip_wardrobe"
    o.endEvent = "nif_exit_wardrobe"
    o.startFactID = 1

    o.name = "Default Interaction"
    o.worldIcon = "ChoiceIcons.OpenWardrobeIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Hanger

    setmetatable(o, { __index = self })
   	return o
end

return wardrobe