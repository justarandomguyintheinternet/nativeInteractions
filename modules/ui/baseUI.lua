local CodewareVersion = "1.16.0"
local ArchiveXLVersion = "1.22.0"
local ModVersion = "1.0.1"
local ModName = "Native Interactions"

local style = require("modules/ui/style")

---@class baseUI
---@field public savedUI savedUI
---@field public editUI editUI
---@field public interactionUI interactionUI
---@field public requirementsIssues string[]
---@field public switchToEdit boolean
---@field public switchToInteraction boolean
local baseUI = {
    savedUI = require("modules/ui/savedUI"),
    editUI = require("modules/ui/editUI"),
    interactionUI = require("modules/ui/interactionUI"),
    requirementsIssues = {},
    switchToEdit = false,
    switchToInteraction = false
}

function baseUI.init()
    if not ArchiveXL then
        table.insert(baseUI.requirementsIssues, "ArchiveXL is not installed")
    elseif not ArchiveXL.Require(ArchiveXLVersion) then
        table.insert(baseUI.requirementsIssues, "ArchiveXL version is outdated, please update to at least" .. ArchiveXLVersion)
    end

    if not Codeware then
        table.insert(baseUI.requirementsIssues, "Codeware is not installed")
    elseif not Codeware.Require(CodewareVersion) then
        table.insert(baseUI.requirementsIssues, "Codeware version is outdated, please update to  at least" .. CodewareVersion)
    end

    if not Game.GetScriptableServiceContainer():GetService("NativeInteractions") then
        table.insert(baseUI.requirementsIssues, "Redscript part of the mod is not installed")
    end

    if not ModArchiveExists("nativeInteractions.archive") then
        table.insert(baseUI.requirementsIssues, "Native Interactions archive is not installed")
    end
end

function baseUI.draw(debug)
    if #baseUI.requirementsIssues > 0 then
        if ImGui.Begin(ModName .. " " .. ModVersion, ImGuiWindowFlags.AlwaysAutoResize) then
            style.mutedText("The following issues are preventing Native Interactions from running:")

            for _, issue in pairs(baseUI.requirementsIssues) do
                ImGui.Text(issue)
            end

            ImGui.End()
        end
        return
    end

    if ImGui.Begin(ModName .. " " .. ModVersion, ImGuiWindowFlags.AlwaysAutoResize) then
        if ImGui.BeginTabBar("Tabbar", ImGuiTabItemFlags.NoTooltip) then
            if ImGui.BeginTabItem("Projects") then
                ImGui.Spacing()
                baseUI.savedUI.draw(debug)
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Edit Project", baseUI.switchToEdit and ImGuiTabItemFlags.SetSelected or ImGuiTabItemFlags.None) then
                baseUI.switchToEdit = false
                ImGui.Spacing()
                baseUI.editUI.draw(debug)
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Edit Interaction", baseUI.switchToInteraction and ImGuiTabItemFlags.SetSelected or ImGuiTabItemFlags.None) then
                baseUI.switchToInteraction = false
                ImGui.Spacing()
                baseUI.interactionUI.draw(debug)
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        ImGui.End()
    end
end

return baseUI