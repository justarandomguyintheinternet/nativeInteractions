local style = require("modules/ui/style")
local workspot = require("modules/classes/interactions/workspot")

---Class for bed interaction
---@class bed : workspot
---@field allowBedrot boolean
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

    o.allowBedrot = false

    setmetatable(o, { __index = self })
   	return o
end

function bed:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_bed_stay", self.allowBedrot and 1 or 0)
    end

    workspot.start(self)
end

function bed:draw()
    workspot.draw(self)

    style.sectionHeaderStart("ACTIONS")

    style.mutedText("Enable Staying In Bed:")
    ImGui.SameLine()
    self.allowBedrot, changed = ImGui.Checkbox('##allowBedrot', self.allowBedrot)
    if changed then self.project:save() end

    style.sectionHeaderEnd()
end

function bed:save()
    local data = workspot.save(self)

    data.allowBedrot = self.allowBedrot

    return data
end

return bed