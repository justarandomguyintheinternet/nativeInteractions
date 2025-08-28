local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local workspot = require("modules/classes/interactions/workspot")

---Class for incense interaction
---@class incense : workspot
---@field maxNodeRefPropertyWidth number?
---@field maxActionPropertyWidth number?
---@field incenseRef string
---@field resetDistance number
---@field used boolean
---@field incensePosition Vector4?
---@field incenseOrientation Quaternion?
local incense = setmetatable({}, { __index = workspot })

function incense:new(mod, project)
    ---@class incense
	local o = workspot.new(self, mod, project)

    o.interactionType = "Incense"
    o.modulePath = "interactions/incense"
    o.scene = "nif\\quest\\incense.scene"
    o.skipFact = "nif_skip_incense"
    o.endEvent = "nif_exit_incense"
    o.startFactID = 8

    o.name = "Incense Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Torch

    o.maxNodeRefPropertyWidth = nil
    o.incenseRef = ""
    o.resetDistance = 8
    o.used = false
    o.incensePosition = nil
    o.incenseOrientation = nil

    setmetatable(o, { __index = self })
   	return o
end

function incense:load(data)
    workspot.load(self, data)

    -- Will reset stick if streamed in
    self:reset()
end

function incense:sessionStart()
    self:reset()
end

function incense:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_incense")] = self.incenseRef
    }

    return data
end

function incense:start()
    if not self.sceneRunning then
        local incense = utils.getEntityByRef(self.incenseRef)
        if incense then
            self.incensePosition = incense:GetWorldPosition()
            self.incenseOrientation = incense:GetWorldOrientation()
        end
    end

    workspot.start(self)
end

function incense:reset()
    if not self.used then return end

    self.used = false
    world.disableInteraction(self.worldInteractionID, false)

    local incense = utils.getEntityByRef(self.incenseRef)

    if not incense then return end

    if self.incensePosition then
        local transform = incense:GetWorldTransform()
        transform:SetPosition(self.incensePosition)
        transform:SetOrientation(self.incenseOrientation)
        incense:SetWorldTransform(transform)
    end

    Game.GetResourceDepot():RemoveResourceFromCache("nif\\quest\\incense_stop.scene")
    resourceHelper.registerPatch("nif\\quest\\incense_stop.scene", self:getPatchData())
    Game.GetQuestsSystem():SetFactStr("nif_interaction_id", 9)
    Game.GetQuestsSystem():SetFactStr("nif_start_signal", 1)
end

function incense:onUpdate()
    if self.sceneRunning and Game.GetQuestsSystem():GetFactStr("nif_scene_active") == 1 then
        self.used = true
        world.disableInteraction(self.worldInteractionID, true)
    end

    if not self.used then return end

    -- Reset incense if far away
    local distance = GetPlayer():GetWorldPosition():Distance(ToVector4(self.worldIconPosition))
    if distance > self.resetDistance and distance < self.resetDistance + 5 then
        self:reset()
    end
end

function incense:draw()
    workspot.draw(self)

    style.sectionHeaderStart("INCENSE")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Incense Stick", "Reset Distance" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Incense, including it's reset range, should be contained within a no-save zone.")

    style.mutedText("Incense Stick:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.incenseRef, changed = ImGui.InputTextWithHint('##incenseRef', '$/mod/#incense_stick', self.incenseRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.incenseRef, true)

    style.mutedText("Reset Distance:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(80)
    self.resetDistance, changed = ImGui.DragFloat("##resetDistance", self.resetDistance, 0.01, 1, 50, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then self.project:save() end
    style.tooltip("Distance from the interaction icon where the incense stick will reset.")
    ImGui.SameLine()
    if ImGui.Button("Reset") then
        self:reset()
    end

    style.sectionHeaderEnd()
end

function incense:save()
    local data = workspot.save(self)

    data.incenseRef = self.incenseRef

    return data
end

return incense