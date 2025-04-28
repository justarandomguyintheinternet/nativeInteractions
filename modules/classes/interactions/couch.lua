local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local workspot = require("modules/classes/interactions/workspot")

---Class for couch interaction
---@class couch : workspot
---@field maxNodeRefPropertyWidth number?
---@field tvRef string
local couch = setmetatable({}, { __index = workspot })

function couch:new(mod, project)
    ---@class couch
	local o = workspot.new(self, mod, project)

    o.interactionType = "Couch"
    o.modulePath = "interactions/couch"
    o.scene = "quest\\sit_tv.scene"
    o.skipFact = "nif_skip_couch"
    o.endEvent = "nif_exit_couch"
    o.startFactID = 2

    o.name = "Couch Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Sofa

    o.maxNodeRefPropertyWidth = nil
    o.tvRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function couch:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_tv")] = self.tvRef
    }

    return data
end

function couch:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "TV" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("TV:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.tvRef, changed = ImGui.InputTextWithHint('##tvRef', '$/mod/#tv', self.tvRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.tvRef)

    style.sectionHeaderEnd()
end

function couch:save()
    local data = workspot.save(self)

    data.tvRef = self.tvRef

    return data
end

return couch