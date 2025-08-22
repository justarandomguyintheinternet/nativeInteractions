local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local workspot = require("modules/classes/interactions/workspot")

---Class for biliard interaction
---@class biliard : workspot
---@field maxNodeRefPropertyWidth number?
---@field stickRef string
---@field ballRef string
---@field cueBallRef string
---@field resetDistance number
---@field used boolean
---@field stickPosition Vector4?
---@field stickOrientation Quaternion?
---@field ballPosition Vector4?
---@field ballOrientation Quaternion?
---@field cueBallPosition Vector4?
---@field cueBallOrientation Quaternion?
---@field cueBallEndPosition Vector4?
---@field cueBallEndOrientation Quaternion?
---@field ballEndPosition Vector4?
---@field ballEndOrientation Quaternion?
local biliard = setmetatable({}, { __index = workspot })

function biliard:new(mod, project)
    ---@class biliard
	local o = workspot.new(self, mod, project)

    o.interactionType = "Biliard"
    o.modulePath = "interactions/biliard"
    o.scene = "nif\\quest\\biliard.scene"
    o.skipFact = "nif_skip_biliard"
    o.endEvent = "nif_exit_biliard"
    o.startFactID = 12

    o.name = "Biliard Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Billiards

    o.maxNodeRefPropertyWidth = nil
    o.stickRef = ""
    o.ballRef = ""
    o.cueBallRef = ""
    o.resetDistance = 10
    o.used = false

    o.stickPosition = nil
    o.stickOrientation = nil
    o.ballPosition = nil
    o.ballOrientation = nil
    o.cueBallPosition = nil
    o.cueBallOrientation = nil

    o.cueBallEndPosition = nil
    o.cueBallEndOrientation = nil
    o.ballEndPosition = nil
    o.ballEndOrientation = nil

    setmetatable(o, { __index = self })
   	return o
end

function biliard:load(data)
    workspot.load(self, data)

    -- Will reset stick if streamed in
    self:reset()
end

function biliard:sessionStart()
    self:reset()
end

function biliard:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_stick")] = self.stickRef,
        [utils.nodeRefStringToHashString("$/nif_ball")] = self.ballRef,
        [utils.nodeRefStringToHashString("$/nif_cueball")] = self.cueBallRef
    }

    return data
end

function biliard:start()
    if not self.sceneRunning then
        local stick = utils.getEntityByRef(self.stickRef)
        if stick then
            self.stickPosition = stick:GetWorldPosition()
            self.stickOrientation = stick:GetWorldOrientation()
        end

        local ball = utils.getEntityByRef(self.ballRef)
        if ball then
            self.ballPosition = ball:GetWorldPosition()
            self.ballOrientation = ball:GetWorldOrientation()
        end

        local cueBall = utils.getEntityByRef(self.cueBallRef)
        if cueBall then
            self.cueBallPosition = cueBall:GetWorldPosition()
            self.cueBallOrientation = cueBall:GetWorldOrientation()
        end
    end

    workspot.start(self)
end

function biliard:reset()
    if not self.used then return end

    self.used = false
    world.disableInteraction(self.worldInteractionID, false)

    self:updateProp(self.stickRef, self.stickPosition, self.stickOrientation)
    self:updateProp(self.ballRef, self.ballPosition, self.ballOrientation)
    self:updateProp(self.cueBallRef, self.cueBallPosition, self.cueBallOrientation)
end

function biliard:updateProp(ref, position, rotation)
    local prop = utils.getEntityByRef(ref)
    if prop and position then
        local transform = prop:GetWorldTransform()
        transform:SetPosition(position)
        transform:SetOrientation(rotation)
        prop:SetWorldTransform(transform)
    end
end

function biliard:onUpdate()
    if self.sceneRunning and Game.GetQuestsSystem():GetFact("nif_scene_active") == 1 then
        self.used = true
        world.disableInteraction(self.worldInteractionID, true)

        local cueBall = utils.getEntityByRef(self.cueBallRef)
        if cueBall then
            local localToWorld = cueBall:FindComponentByName("ball_b_billiard0582"):GetLocalToWorld()
            self.cueBallEndPosition = localToWorld:GetTranslation()
            self.cueBallEndOrientation = localToWorld:GetRotation():ToQuat()
        end

        local ball = utils.getEntityByRef(self.ballRef)
        if ball then
            local localToWorld = ball:FindComponentByName("ball_b_billiard0582"):GetLocalToWorld()
            self.ballEndPosition = localToWorld:GetTranslation()
            self.ballEndOrientation = localToWorld:GetRotation():ToQuat()
        end
    end

    if self.used and not self.sceneRunning then
        self:updateProp(self.cueBallRef, self.cueBallEndPosition, self.cueBallEndOrientation)
        self:updateProp(self.ballRef, self.ballEndPosition, self.ballEndOrientation)
    end

    if not self.used then return end

    -- Reset scene if far away
    local distance = GetPlayer():GetWorldPosition():Distance(ToVector4(self.worldIconPosition))
    if distance > self.resetDistance and distance < self.resetDistance + 5 then
        self:reset()
    end
end

function biliard:draw()
    workspot.draw(self)

    style.sectionHeaderStart("BILLIARD")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Billiard Stick", "Ball", "Cue Ball", "Reset Distance" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Billiard Stick:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.stickRef, changed = ImGui.InputTextWithHint('##stickRef', '$/mod/#billiard_stick', self.stickRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.stickRef, true)

    style.mutedText("Ball:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.ballRef, changed = ImGui.InputTextWithHint('##ballRef', '$/mod/#billiard_ball', self.ballRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.ballRef, true)

    style.mutedText("Cue Ball:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.cueBallRef, changed = ImGui.InputTextWithHint('##cueBallRef', '$/mod/#billiard_cue_ball', self.cueBallRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.cueBallRef, true)

    style.mutedText("Reset Distance:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(80)
    self.resetDistance, changed = ImGui.DragFloat("##resetDistance", self.resetDistance, 0.01, 1, 50, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then self.project:save() end
    style.tooltip("Distance from the interaction icon where the interaction will reset.")
    ImGui.SameLine()
    if ImGui.Button("Reset") then
        self:reset()
    end

    style.sectionHeaderEnd()
end

function biliard:save()
    local data = workspot.save(self)

    data.stickRef = self.stickRef
    data.ballRef = self.ballRef
    data.cueBallRef = self.cueBallRef

    return data
end

return biliard