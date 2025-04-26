local style = require("modules/ui/style")

local interactions = {
    { name = "", class = require("modules/classes/interactions/wardrobe") },
    { name = "", class = require("modules/classes/interactions/workspot") }
}

---@class editUI
---@field public mod mod?
---@field public project project?
local editUI = {
    mod = nil,
    project = nil,
    newInteractionName = "New Interaction",
    newInteractionIndex = 0,
    interactionNames = nil
}

local function getInteractionNames()
    local interactionNames = {}
    for _, entry in pairs(interactions) do
        local instance = entry.class:new()
        table.insert(interactionNames, instance.editorIcon .. " " .. instance.interactionType)
    end

    return interactionNames
end

local interactionNames = getInteractionNames()

---@param mod mod
function editUI.draw(mod)
    if not editUI.mod then
        editUI.mod = mod
    end

    if not editUI.project then
        style.mutedText("No project loaded.")
        return
    end

    if not editUI.project.enabled then
        style.mutedText("Project is disabled.")
        return
    end

    style.setNextItemWidth(150)
    editUI.newInteractionIndex, _ = ImGui.Combo("##newInteractionIndex", editUI.newInteractionIndex, interactionNames, #interactionNames)
    ImGui.SameLine()
    style.setNextItemWidth(125)
    editUI.newInteractionName, _ = ImGui.InputTextWithHint("##newInteractionName", "New Interaction Name...", editUI.newInteractionName, 50)
    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.Plus) then
        local data = interactions[editUI.newInteractionIndex + 1].class:new(editUI.mod, editUI.project)
        editUI.project:addInteraction(data, editUI.newInteractionName)
    end

    style.spacedSeparator()

    for key, entry in pairs(editUI.project.interactions) do
        ImGui.PushID(key)

        local sceneActive = Game.GetQuestsSystem():GetFact("nif_scene_active") == 1
        local state = (sceneActive and entry.sceneRunning) and "In Scene" or (entry.sceneRunning and "Choice Active" or "Not Running")
        local color = (sceneActive and entry.sceneRunning) and 0xFF00FF00 or (entry.sceneRunning and 0x8000FFFF or 0x80FFFFFF)

        style.styledText(entry.editorIcon, color)
        style.tooltip(state)
        ImGui.SameLine()
        entry.name, _ = ImGui.InputTextWithHint("##Name", "Name...", entry.name, 50)
        if ImGui.IsItemDeactivatedAfterEdit() then
            editUI.project:save()
        end
        ImGui.SameLine()
        style.pushButtonNoBG(true)
        if ImGui.Button(IconGlyphs.CogOutline) then
            editUI.mod.baseUI.interactionUI.interaction = entry
            editUI.mod.baseUI.interactionUI.project = editUI.project
            editUI.mod.baseUI.switchToInteraction = true
        end
        style.tooltip("Edit Interaction")
        ImGui.SameLine()
        if ImGui.Button(IconGlyphs.TrashCanOutline) then
            editUI.project:removeInteraction(entry)
            if editUI.mod.baseUI.interactionUI.interaction == entry then
                editUI.mod.baseUI.interactionUI.interaction = nil
            end
        end
        style.tooltip("Delete Interaction")
        style.pushButtonNoBG(false)

        ImGui.PopID()
    end
end

return editUI