local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for guitar interaction
---@class guitar : workspot
---@field maxNodeRefPropertyWidth number?
---@field guitarRef string?
local guitar = setmetatable({}, { __index = workspot })

function guitar:new(mod, project)
    ---@class guitar
	local o = workspot.new(self, mod, project)

    o.interactionType = "Guitar"
    o.modulePath = "interactions/guitar"
    o.scene = "nif\\quest\\guitar.scene"
    o.skipFact = "nif_skip_guitar"
    o.endEvent = "nif_exit_guitar"
    o.startFactID = 10

    o.name = "Guitar Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.GuitarElectric

    o.maxNodeRefPropertyWidth = nil
    o.guitarRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function guitar:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_guitar")] = self.guitarRef
    }

    return data
end

function guitar:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Guitar" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Guitar:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.guitarRef, changed = ImGui.InputTextWithHint('##guitarRef', '$/mod/#guitar', self.guitarRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.guitarRef)

    style.sectionHeaderEnd()
end

function guitar:save()
    local data = workspot.save(self)

    data.guitarRef = self.guitarRef

    return data
end

return guitar