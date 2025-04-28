local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local interaction = require("modules/classes/interaction")

---Class for base workspot interaction
---@class workspot : interaction
---@field workspotPosition {x: number, y: number, z: number}?
---@field workspotRotation {roll: number, pitch: number, yaw: number}?
---@field workspotPositionPending boolean
---@field workspotRotationPending boolean
---@field previewEntityID number?
---@field maxWorkspotPropertyWidth number?
local workspot = setmetatable({}, { __index = interaction })

function workspot:new(mod, project)
    ---@class workspot
	local o = interaction.new(self, mod, project)

    o.interactionType = "Couch"
    o.modulePath = "interactions/workspot"
    o.scene = "nif\\quest\\couch.scene"
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
    o.workspotPositionPending = false
    o.workspotRotationPending = false

    o.previewEntityID = nil

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

    data.animationPosition = ToVector4(self.workspotPosition)
    data.animationRotation = ToEulerAngles(self.workspotRotation)

    return data
end

function workspot:stop()
    self.workspotPositionPending = false
    self.workspotRotationPending = false
    interaction.stop(self)
end

function workspot:sessionStart()
    self.previewEntityID = nil
end

function workspot:editStart()
    local spec = StaticEntitySpec.new()
    spec.templatePath = "nif\\arrow\\arrow.ent"
    spec.position = ToVector4(self.workspotPosition)
    spec.orientation = ToEulerAngles(self.workspotRotation):ToQuat()
    spec.attached = true
    self.previewEntityID = Game.GetStaticEntitySystem():SpawnEntity(spec)
end

function workspot:editEnd()
    if not self.previewEntityID then return end
    Game.GetStaticEntitySystem():DespawnEntity(self.previewEntityID)
end

function workspot:updatePreview()
    if not self.previewEntityID then return end

    local entity = Game.GetStaticEntitySystem():GetEntity(self.previewEntityID)
    if not entity then return end

    local transform = entity:GetWorldTransform()
    transform:SetPosition(ToVector4(self.workspotPosition))
    transform:SetOrientationEuler(ToEulerAngles(self.workspotRotation))
    entity:SetWorldTransform(transform)
end

function workspot:draw()
    style.sectionHeaderStart("WORKSPOT POSITION")

    if not self.maxWorkspotPropertyWidth then
        self.maxWorkspotPropertyWidth = utils.getTextMaxWidth({ "Workspot Position", "Workspot Orientation" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Workspot Position:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxWorkspotPropertyWidth)
    self.workspotPosition, changed, finished = self.mod.baseUI.interactionUI.drawPosition(self.workspotPosition, "position")
    if changed then
        self:updatePreview()
        self.project:save()
    end
    if finished and self.sceneRunning then
        self.workspotPositionPending = true
    end
    if self.workspotPositionPending then
        ImGui.SameLine()
        style.styledText(IconGlyphs.AlertOutline, 0xFF0000FF)
        style.tooltip("Workspot position will be updated next time the interaction prompt gets hidden.")
    end

    style.mutedText("Workspot Orientation:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxWorkspotPropertyWidth)
    self.workspotRotation.yaw, changed, finished = self.mod.baseUI.interactionUI.drawYaw(self.workspotRotation.yaw, "orientation")
    if changed then
        self:updatePreview()
        self.project:save()
    end
    if finished and self.sceneRunning then
        self.workspotRotationPending = true
    end
    if self.workspotRotationPending then
        ImGui.SameLine()
        style.styledText(IconGlyphs.AlertOutline, 0xFF0000FF)
        style.tooltip("Workspot orientation will be updated next time the interaction prompt gets hidden.")
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