local style = require("modules/ui/style")
local workspot = require("modules/classes/interactions/workspot")

---Class for netrunner chair interaction
---@class netrunnerChair : workspot
---@field appearanceOption number
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

    o.appearanceOption = 0

    setmetatable(o, { __index = self })
   	return o
end

function netrunnerChair:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_netrunner_options", self.appearanceOption)
    end

    workspot.start(self)
end

function netrunnerChair:draw()
    workspot.draw(self)

    style.sectionHeaderStart("ACTIONS")

    style.mutedText("Appearance Editing Options:")
    ImGui.SameLine()
    style.setNextItemWidth(100)
    self.appearanceOption, changed = ImGui.Combo("##appearanceOptions", self.appearanceOption, { "None", "Hairdresser", "Ripperdoc", "New Game" }, 4)
    if changed then
        Game.GetQuestsSystem():SetFactStr("nif_netrunner_options", self.appearanceOption)
        self.project:save()
    end

    style.sectionHeaderEnd()
end

function netrunnerChair:save()
    local data = workspot.save(self)

    data.appearanceOption = self.appearanceOption

    return data
end

return netrunnerChair