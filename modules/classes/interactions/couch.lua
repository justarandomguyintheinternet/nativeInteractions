local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local workspot = require("modules/classes/interactions/workspot")

---Class for couch interaction
---@class couch : workspot
---@field maxNodeRefPropertyWidth number?
---@field maxActionPropertyWidth number?
---@field tvRef string
---@field enableTVControls boolean
---@field sitType number
local couch = setmetatable({}, { __index = workspot })

function couch:new(mod, project)
    ---@class couch
	local o = workspot.new(self, mod, project)

    o.interactionType = "Couch"
    o.modulePath = "interactions/couch"
    o.scene = "nif\\quest\\sit_tv.scene"
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
    o.maxActionPropertyWidth = nil
    o.tvRef = ""
    o.enableTVControls = false
    o.sitType = 1

    setmetatable(o, { __index = self })
   	return o
end

function couch:load(data)
    workspot.load(self, data)

    CName.add("nif_tv_controls")
    CName.add("nif_sit_type")
end

function couch:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_tv")] = self.tvRef
    }

    return data
end

function couch:onUpdate()
    if self.sceneRunning then
        Game.GetQuestsSystem():SetFact("nif_tv_controls", self.enableTVControls and 1 or 0)
        Game.GetQuestsSystem():SetFact("nif_sit_type", self.sitType)
    end
end

function couch:draw()
    workspot.draw(self)

    style.sectionHeaderStart("ACTIONS")

    if not self.maxActionPropertyWidth then
        self.maxActionPropertyWidth = utils.getTextMaxWidth({ "Sit Animation", "Enable TV Controls" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Sit Animation:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxActionPropertyWidth)
    style.setNextItemWidth(300)
    local sitType, changed = ImGui.Combo("##sitType", self.sitType - 1, { "Legs Normal", "Legs Wide", "Legs Crossed" }, 3)
    if changed then
        self.sitType = sitType + 1
        self.project:save()
    end

    style.mutedText("Enable TV Controls:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxActionPropertyWidth)
    self.enableTVControls, changed = ImGui.Checkbox('##enableTVControls', self.enableTVControls)
    if changed then self.project:save() end

    style.sectionHeaderEnd()

    if not self.enableTVControls then return end

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
    data.enableTVControls = self.enableTVControls
    data.sitType = self.sitType

    return data
end

return couch