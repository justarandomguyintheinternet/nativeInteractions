local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local interaction = require("modules/classes/interaction")

---Class for base workspot interaction
---@class workspot : interaction
---@field workspotPosition {x: number, y: number, z: number}?
---@field workspotRotation {roll: number, pitch: number, yaw: number}?
---@field maxWorkspotPropertyWidth number?
local workspot = setmetatable({}, { __index = interaction })

function workspot:new(mod, project)
    ---@class workspot
	local o = interaction.new(self, mod, project)

    o.interactionType = "Couch"
    o.modulePath = "interactions/couch"
    o.scene = "quest\\couch.scene"
    o.skipFact = "nif_skip_couch"
    o.endEvent = "nif_exit_couch"
    o.startFactID = 2

    o.name = "Default Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Sofa

    o.workspotPosition = nil
    o.workspotRotation = nil

    o.maxWorkspotPropertyWidth = nil

    setmetatable(o, { __index = self })
   	return o
end

function workspot:load(data)
    interaction.load(self, data)

    self.workspotPosition = type(self.workspotPosition) == "nil" and utils.fromVector(GetPlayer():GetWorldPosition()) or self.workspotPosition
    self.workspotRotation = type(self.workspotRotation) == "nil" and utils.fromEuler(GetPlayer():GetWorldOrientation():ToEulerAngles()) or self.workspotRotation
end

function workspot:getPatchData()
    local data = interaction.getPatchData(self)

    data.animationPosition = self.workspotPosition
    data.animationRotation = self.workspotRotation

    return data
end

function workspot:draw()
    style.sectionHeaderStart("WORKSPOT POSITION")

    if not self.maxWorkspotPropertyWidth then
        self.maxWorkspotPropertyWidth = utils.getTextMaxWidth({ "Workspot Position", "Workspot Orientation" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Workspot Position:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxWorkspotPropertyWidth)
    self.workspotPosition, changed = self.mod.baseUI.interactionUI.drawPosition(self.workspotPosition, "workspot")
    if changed then
        self.project:save()
    end
    if ImGui.IsItemDeactivatedAfterEdit() then
        if self.sceneRunning then
            self:stop()
            self:start()
        end
    end

    style.sectionHeaderEnd()
end

function workspot:save()
    local data = interaction.save(self)

    data.workspotPosition = utils.deepcopy(self.workspotPosition)
    data.workspotRotation = utils.deepcopy(self.workspotRotation)

    return data
end

return workspot