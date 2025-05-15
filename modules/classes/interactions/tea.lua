local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for tea interaction
---@class tea : workspot
---@field maxNodeRefPropertyWidth number?
---@field teapotRef string?
---@field teacupRef string?
local tea = setmetatable({}, { __index = workspot })

function tea:new(mod, project)
    ---@class tea
	local o = workspot.new(self, mod, project)

    o.interactionType = "Tea"
    o.modulePath = "interactions/tea"
    o.scene = "nif\\quest\\tea.scene"
    o.skipFact = "nif_skip_tea"
    o.endEvent = "nif_exit_tea"
    o.startFactID = 3

    o.name = "Tea Interaction"
    o.worldIcon = "ChoiceIcons.DrinkIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.TeaOutline

    o.maxNodeRefPropertyWidth = nil
    o.teapotRef = ""
    o.teacupRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function tea:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_teacup")] = self.teacupRef,
        [utils.nodeRefStringToHashString("$/nif_teapot")] = self.teapotRef
    }

    return data
end

function tea:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Teapot", "Teacup" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Teapot:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.teapotRef, changed = ImGui.InputTextWithHint('##teapot', '$/mod/#teapot', self.teapotRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.teapotRef, true)

    style.mutedText("Teacup:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.teacupRef, changed = ImGui.InputTextWithHint('##teacup', '$/mod/#teacup', self.teacupRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.teacupRef, true)

    style.sectionHeaderEnd()
end

function tea:save()
    local data = workspot.save(self)

    data.teapotRef = self.teapotRef
    data.teacupRef = self.teacupRef

    return data
end

return tea