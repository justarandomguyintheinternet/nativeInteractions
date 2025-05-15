local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for basketball interaction
---@class basketball : workspot
---@field maxNodeRefPropertyWidth number?
---@field basketballRef string?
---@field ballPosition Vector4?
---@field ballOrientation Quaternion?
local basketball = setmetatable({}, { __index = workspot })

function basketball:new(mod, project)
    ---@class basketball
	local o = workspot.new(self, mod, project)

    o.interactionType = "Basketball"
    o.modulePath = "interactions/basketball"
    o.scene = "nif\\quest\\basketball.scene"
    o.skipFact = "nif_skip_basketball"
    o.endEvent = "nif_exit_basketball"
    o.startFactID = 20

    o.name = "Basketball Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Basketball

    o.maxNodeRefPropertyWidth = nil
    o.basketballRef = ""
    o.ballPosition = nil
    o.ballOrientation = nil

    setmetatable(o, { __index = self })
   	return o
end

function basketball:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_basketball")] = self.basketballRef
    }

    return data
end

function basketball:start()
    if not self.sceneRunning then
        local ball = utils.getEntityByRef(self.basketballRef)
        if ball then
            self.ballPosition = ball:GetWorldPosition()
            self.ballOrientation = ball:GetWorldOrientation()
        end
    end

    workspot.start(self)
end

function basketball:onSceneEnd()
    local ball = utils.getEntityByRef(self.basketballRef)

    if ball then
        local transform = ball:GetWorldTransform()
        transform:SetPosition(self.ballPosition)
        transform:SetOrientation(self.ballOrientation)
        ball:SetWorldTransform(transform)
    end
end

function basketball:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Basketball" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Basketball:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.basketballRef, changed = ImGui.InputTextWithHint('##basketballRef', '$/mod/#basketball', self.basketballRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.basketballRef, true)

    style.sectionHeaderEnd()
end

function basketball:save()
    local data = workspot.save(self)

    data.basketballRef = self.basketballRef

    return data
end

return basketball