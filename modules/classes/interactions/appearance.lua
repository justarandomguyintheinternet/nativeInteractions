local style = require("modules/ui/style")
local interaction = require("modules/classes/interaction")

---Class for appearance interaction
---@class appearance : interaction
---@field appearanceOption number
local appearance = setmetatable({}, { __index = interaction })

function appearance:new(mod, project)
	local o = interaction.new(self, mod, project)

    o.interactionType = "Appearance"
    o.modulePath = "interactions/appearance"
    o.scene = "nif\\quest\\appearance.scene"
    o.skipFact = "nif_skip_appearance"
    o.endEvent = "nif_exit_appearance"
    o.startFactID = 23

    o.name = "Default Interaction"
    o.worldIcon = "ChoiceIcons.HairdresserIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Lipstick

    o.appearanceOption = 0

    setmetatable(o, { __index = self })
   	return o
end

function appearance:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_appearance_options", self.appearanceOption)
    end

    interaction.start(self)
end

function appearance:draw()
    interaction.draw(self)

    style.sectionHeaderStart("ACTIONS")

    style.mutedText("Appearance Editing Options:")
    ImGui.SameLine()
    style.setNextItemWidth(100)
    self.appearanceOption, changed = ImGui.Combo("##appearanceOptions", self.appearanceOption, { "Hairdresser", "Ripperdoc", "New Game" }, 3)
    if changed then
        Game.GetQuestsSystem():SetFactStr("nif_appearance_options", self.appearanceOption)
        self.project:save()
    end

    style.sectionHeaderEnd()
end

function appearance:save()
    local data = interaction.save(self)

    data.appearanceOption = self.appearanceOption

    return data
end

return appearance