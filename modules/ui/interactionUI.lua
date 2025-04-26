local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local world = require("modules/utils/worldInteraction")

---@class interactionUI
---@field public mod mod?
---@field public interaction interaction?
---@field public project project?
---@field public maxBasePropertyWidth number?
local interactionUI = {
    mod = nil,
    interaction = nil,
    project = nil,
    maxBasePropertyWidth = nil
}

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

    ImGui.PushItemWidth(80 * style.viewSize)
    position.x, update = ImGui.DragFloat("##x", position.x, steps, -99999, 99999, formatText .. " X", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    ImGui.SameLine()
    position.y, update = ImGui.DragFloat("##y", position.y, steps, -99999, 99999, formatText .. " Y", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    ImGui.SameLine()
    position.z, update = ImGui.DragFloat("##z", position.z, steps, -99999, 99999, formatText .. " Z", ImGuiSliderFlags.NoRoundToFormat)
    changed = changed or update
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.AccountArrowLeftOutline) then
        position = utils.fromVector(GetPlayer():GetWorldPosition())
        changed = true
    end
    style.tooltip("Set to player position")

    ImGui.PopID()

    return position, changed
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
    interactionUI.interaction.worldIconPosition, changed = interactionUI.drawPosition(interactionUI.interaction.worldIconPosition, "icon")
    if changed then
        world.updateInteractionPosition(interactionUI.interaction.worldInteractionID, ToVector4(interactionUI.interaction.worldIconPosition))
        interactionUI.project:save()
    end

    style.mutedText("Icon Visibility Range:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    style.setNextItemWidth(80)
    interactionUI.interaction.worldIconRange, changed = ImGui.DragFloat("##worldIconRange", interactionUI.interaction.worldIconRange, 0.01, 0.1, 100, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then
        world.interactions[interactionUI.interaction.worldInteractionID].iconRange = interactionUI.interaction.worldIconRange
        interactionUI.project:save()
    end

    style.mutedText("Interaction Range:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(interactionUI.maxBasePropertyWidth)
    style.setNextItemWidth(80)
    interactionUI.interaction.interactionRange, changed = ImGui.DragFloat("##interactionRange", interactionUI.interaction.interactionRange, 0.01, 0.1, 100, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then
        world.interactions[interactionUI.interaction.worldInteractionID].interactionRange = interactionUI.interaction.interactionRange
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
    end
    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.Refresh) then
    end
    style.spacedSeparator()

    style.mutedText(string.upper(interactionUI.interaction.interactionType) .. " | " .. interactionUI.interaction.name)
    style.spacedSeparator()

    interactionUI.drawBaseOptions()
    interactionUI.interaction:draw()
end

return interactionUI