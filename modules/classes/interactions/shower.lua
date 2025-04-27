local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for shower interaction
---@class shower : workspot
---@field maxNodeRefPropertyWidth number?
---@field showerRef string?
local shower = setmetatable({}, { __index = workspot })

function shower:new(mod, project)
    ---@class shower
	local o = workspot.new(self, mod, project)

    o.interactionType = "Shower"
    o.modulePath = "interactions/shower"
    o.scene = "quest\\shower.scene"
    o.skipFact = "nif_skip_shower"
    o.endEvent = "nif_exit_shower"
    o.startFactID = 5

    o.name = "Shower Interaction"
    o.worldIcon = "ChoiceIcons.ShowerIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.ShowerHead

    o.maxNodeRefPropertyWidth = nil
    o.showerRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function shower:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_shower")] = self.showerRef
    }

    return data
end

function shower:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Shower" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Shower:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.showerRef, changed = ImGui.InputTextWithHint('##showerRef', '$/mod/#shower', self.showerRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.showerRef)

    style.sectionHeaderEnd()
end

function shower:save()
    local data = workspot.save(self)

    data.showerRef = self.showerRef

    return data
end

return shower