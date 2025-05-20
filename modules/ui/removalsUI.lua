local style = require("modules/ui/style")
local removals = require("modules/removalManager")

---@class removalsUI
---@field public mod mod?
---@field public project project?
local removalsUI = {
    mod = nil,
    project = nil
}

function removalsUI.drawScene(scene)
    if ImGui.TreeNodeEx(scene.name, ImGuiTreeNodeFlags.SpanFullWidth) then
        for key, interaction in pairs(scene.interactions) do
            local projects = removals.getProjectsByRemoval(key, removalsUI.project)
            local alreadyRemoved = #projects > 0
            local tooltip = ""

            if alreadyRemoved then
                tooltip = "Already removed in:\n"
                for _, project in pairs(projects) do
                    tooltip = tooltip .. project.name .. "\n"
                end
            end

            style.pushStyleColor(alreadyRemoved, ImGuiCol.FrameBg, 0x6F006FFF)
            style.pushStyleColor(alreadyRemoved, ImGuiCol.FrameBgHovered, 0xFF006FFF)

            local state, changed = ImGui.Checkbox(interaction.name, removalsUI.project.removals[key] == nil)
            if changed then
                if not state then
                    removalsUI.project.removals[key] = true
                else
                    removalsUI.project.removals[key] = nil
                end

                removalsUI.project:save()
                removals.registerPatches()
            end

            style.popStyleColor(alreadyRemoved, 2)
            if alreadyRemoved then
                style.tooltip(tooltip)
            end
        end

        ImGui.TreePop()
    end
end

---@param mod mod
function removalsUI.draw(mod)
    if not removalsUI.mod then
        removalsUI.mod = mod
    end

    if not removalsUI.project then
        style.mutedText("No project loaded.")
        return
    end

    style.mutedText("Removals will update when leaving and re-entering the apartment / area.")
    style.spacedSeparator()

    for _, scene in pairs(removals.data) do
        removalsUI.drawScene(scene)
    end
end

return removalsUI