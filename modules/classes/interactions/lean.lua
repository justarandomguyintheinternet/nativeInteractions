local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local workspot = require("modules/classes/interactions/workspot")

---Class for lean interaction
---@class lean : workspot
---@field maxActionPropertyWidth number?
---@field enableSmoke boolean
local lean = setmetatable({}, { __index = workspot })

function lean:new(mod, project)
    ---@class lean
	local o = workspot.new(self, mod, project)

    o.interactionType = "Lean"
    o.modulePath = "interactions/lean"
    o.scene = "nif\\quest\\lean.scene"
    o.skipFact = "nif_skip_lean"
    o.endEvent = "nif_exit_lean"
    o.startFactID = 16

    o.name = "Lean Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Fence

    o.maxActionPropertyWidth = nil
    o.enableSmoke = true

    setmetatable(o, { __index = self })
   	return o
end

function lean:load(data)
    workspot.load(self, data)

    CName.add("nif_lean_enable_smoke")
end

function lean:onUpdate()
    if self.sceneRunning then
        Game.GetQuestsSystem():SetFact("nif_lean_enable_smoke", self.enableSmoke and 1 or 0)
    end
end

function lean:draw()
    workspot.draw(self)

    style.sectionHeaderStart("ACTIONS")

    if not self.maxActionPropertyWidth then
        self.maxActionPropertyWidth = utils.getTextMaxWidth({ "Enable Smoking" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Enable Smoking:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxActionPropertyWidth)
    self.enableSmoke, changed = ImGui.Checkbox('##enableSmoke', self.enableSmoke)
    if changed then self.project:save() end

    style.sectionHeaderEnd()
end

function lean:save()
    local data = workspot.save(self)

    data.enableSmoke = self.enableSmoke

    return data
end

return lean