local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local world = require("modules/utils/worldInteraction")

---@class interactionUI
---@field public mod mod?
---@field public interaction interaction?
---@field public project project?
---@field public maxBasePropertyWidth number?
---@field public paused boolean
---@field public cameraExternal boolean
---@field public fastForward boolean
local interactionUI = {
    mod = nil,
    interaction = nil,
    project = nil,
    maxBasePropertyWidth = nil,
    paused = false,
    cameraExternal = false,
    fastForward = false
}

function interactionUI.projectUnload()
    if interactionUI.interaction then
        interactionUI.setCameraExternal(false)
        interactionUI.setPaused(false)
        interactionUI.setFastForward(false)
        interactionUI.interaction:editEnd()
        interactionUI.interaction = nil
    end
end

function interactionUI.setPaused(state)
    interactionUI.paused = state
    interactionUI.fastForward = false

    if state then
        Game.GetTimeSystem():SetTimeDilation("nif", 0.000000001)
    else
        Game.GetTimeSystem():UnsetTimeDilation("nif")
    end
end

function interactionUI.setCameraExternal(state)
    interactionUI.cameraExternal = state

    if state then
        Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, -2, 0, 0))
        Game.GetPlayer():GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0, 0, 0, 1))
        Game.GetPlayer():GetFPPCameraComponent().pitchMax = 89
        Game.GetPlayer():GetFPPCameraComponent().pitchMin = -89
        Game.GetPlayer():GetFPPCameraComponent().yawMaxRight = -360
        Game.GetPlayer():GetFPPCameraComponent().yawMaxLeft = 360
    else
        Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0, 0, 0, 0))
        Game.GetPlayer():GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0, 0, 0, 1))
    end
end

function interactionUI.setFastForward(state)
    interactionUI.fastForward = state
    interactionUI.paused = false

    if state then
        Game.GetTimeSystem():SetTimeDilation("nif", 2.5)
    else
        Game.GetTimeSystem():UnsetTimeDilation("nif")
    end
end

function interactionUI.drawPosition(position, key)
    local steps = 0.0075
    local formatText = "%.2f"

    ImGui.PushID(key)

	if ImGui.IsKeyDown(ImGuiKey.LeftShift) then
		steps = steps * 0.01
		formatText = "%.3f"
	end

    local changed = false
    local update = false
    local finished = false

    ImGui.PushItemWidth(80 * style.viewSize)
    position.x, update = ImGui.DragFloat("##x", position.x, steps, -99999, 99999, formatText .. " X", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    finished = finished or ImGui.IsItemDeactivatedAfterEdit()
    ImGui.SameLine()
    position.y, update = ImGui.DragFloat("##y", position.y, steps, -99999, 99999, formatText .. " Y", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    finished = finished or ImGui.IsItemDeactivatedAfterEdit()
    ImGui.SameLine()
    position.z, update = ImGui.DragFloat("##z", position.z, steps, -99999, 99999, formatText .. " Z", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    finished = finished or ImGui.IsItemDeactivatedAfterEdit()
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.AccountArrowLeftOutline) then
        position = utils.fromVector(GetPlayer():GetWorldPosition())
        changed = true
        finished = true
    end
    style.tooltip("Set to player position")

    ImGui.PopID()

    return position, changed, finished
end

function interactionUI.drawYaw(yaw, key)
    local steps = 0.025
    local formatText = "%.2f"

    ImGui.PushID(key)

	if ImGui.IsKeyDown(ImGuiKey.LeftShift) then
		steps = steps * 0.01
		formatText = "%.3f"
	end

    local changed = false

    ImGui.PushItemWidth(80 * style.viewSize)
    yaw, changed = ImGui.DragFloat("##yaw", yaw, steps, -99999, 99999, formatText .. " Yaw", ImGuiSliderFlags.NoRoundToFormat)
    local finished = ImGui.IsItemDeactivatedAfterEdit()

    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.AccountArrowLeftOutline) then
        yaw = GetPlayer():GetWorldOrientation():ToEulerAngles().yaw
        changed = true
    end
    style.tooltip("Set to player rotation")

    ImGui.PopID()

    return yaw, changed, finished
end

function interactionUI.drawBaseOptions()
    if not interactionUI.maxBasePropertyWidth then
        interactionUI.maxBasePropertyWidth = utils.getTextMaxWidth({ "Name", "Icon Position", "Icon Visibility Range", "Interaction Range", "Interaction Angle" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Name:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    interactionUI.interaction.name, _ = ImGui.InputTextWithHint('##Name', 'Name...', interactionUI.interaction.name, 50)
    if ImGui.IsItemDeactivatedAfterEdit() then
        interactionUI.project:save()
    end

    style.mutedText("Icon Position:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    interactionUI.interaction.worldIconPosition, changed, _ = interactionUI.drawPosition(interactionUI.interaction.worldIconPosition, "icon")
    if changed then
        world.updateInteractionPosition(interactionUI.interaction.worldInteractionID, ToVector4(interactionUI.interaction.worldIconPosition))
        interactionUI.project:save()
    end

    style.mutedText("Icon Visibility Range:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    style.setNextItemWidth(80)
    interactionUI.interaction.worldIconRange, changed = ImGui.DragFloat("##worldIconRange", interactionUI.interaction.worldIconRange, 0.01, 0.1, 12, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then
        world.interactions[interactionUI.interaction.worldInteractionID].iconRange = interactionUI.interaction.worldIconRange ^ 2
        interactionUI.project:save()
    end

    style.mutedText("Interaction Range:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    style.setNextItemWidth(80)
    interactionUI.interaction.interactionRange, changed = ImGui.DragFloat("##interactionRange", interactionUI.interaction.interactionRange, 0.01, 0.1, 12, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then
        world.interactions[interactionUI.interaction.worldInteractionID].interactionRange = interactionUI.interaction.interactionRange ^ 2
        interactionUI.project:save()
    end

    style.mutedText("Interaction Angle:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    style.setNextItemWidth(80)
    interactionUI.interaction.interactionAngle, changed = ImGui.DragFloat("##interactionAngle", interactionUI.interaction.interactionAngle, 0.01, 0.1, 100, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then
        world.interactions[interactionUI.interaction.worldInteractionID].angle = interactionUI.interaction.interactionAngle
        interactionUI.project:save()
    end
end

---@param mod mod
function interactionUI.draw(mod)
    if not interactionUI.mod then
        interactionUI.mod = mod
    end

    if not interactionUI.interaction then
        style.mutedText("No interaction loaded.")
        return
    end

    if style.buttonNoBG(IconGlyphs.Close) then
        interactionUI.interaction:editEnd()
        interactionUI.interaction = nil
        interactionUI.setPaused(false)
        interactionUI.setCameraExternal(false)
        interactionUI.setFastForward(false)
        return
    end
    style.tooltip("Stop editing")
    ImGui.SameLine()
    if style.buttonNoBG(interactionUI.paused and IconGlyphs.Play or IconGlyphs.Pause) then
        interactionUI.setPaused(not interactionUI.paused)
    end
    style.tooltip(interactionUI.paused and "Resume Game" or "Pause Game")
    ImGui.SameLine()
    if style.buttonNoBG(interactionUI.fastForward and IconGlyphs.FastForward or IconGlyphs.FastForwardOutline) then
        interactionUI.setFastForward(not interactionUI.fastForward)
    end
    style.tooltip(interactionUI.fastForward and "Normal Speed" or "Fast Forward")
    ImGui.SameLine()
    if style.buttonNoBG(interactionUI.cameraExternal and IconGlyphs.CameraOutline or IconGlyphs.CameraFlipOutline) then
        interactionUI.setCameraExternal(not interactionUI.cameraExternal)
    end
    style.tooltip(interactionUI.cameraExternal and "Disable External Camera" or "Enable External Camera")

    style.spacedSeparator()

    style.mutedText(string.upper(interactionUI.interaction.interactionType) .. " | " .. interactionUI.interaction.name)
    style.spacedSeparator()

    interactionUI.drawBaseOptions()
    interactionUI.interaction:draw()
end

return interactionUI