local CodewareVersion = "1.21.0"
local ArchiveXLVersion = "1.28.0"
local ModVersion = "1.1.5"
local CETVersion = "1.38.1"
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
    removalsUI = require("modules/ui/removalsUI"),
    requirementsIssues = {},
    switchToEdit = false,
    switchToInteraction = false
}

local function parseVersion(version)
    local major, minor, patch = version:match("^v?(%d+)%.(%d+)%.(%d+)")

    return tonumber(major), tonumber(minor), tonumber(patch)
end

local function requireCET(requiredVersion)
    local cMajor, cMinor, cPatch = parseVersion(GetVersion():gsub("^v", ""))
    local rMajor, rMinor, rPatch = parseVersion(requiredVersion)

    if cMajor ~= rMajor then
        return cMajor > rMajor
    elseif cMinor ~= rMinor then
        return cMinor > rMinor
    else
        return cPatch >= rPatch
    end
end

function baseUI.init()
    if not ArchiveXL then
        table.insert(baseUI.requirementsIssues, "ArchiveXL is not installed")
    elseif not ArchiveXL.Require(ArchiveXLVersion) then
        table.insert(baseUI.requirementsIssues, "ArchiveXL version is outdated, please update to at least " .. ArchiveXLVersion)
    end

    if not Codeware then
        table.insert(baseUI.requirementsIssues, "Codeware is not installed")
    elseif not Codeware.Require(CodewareVersion) then
        table.insert(baseUI.requirementsIssues, "Codeware version is outdated, please update to at least " .. CodewareVersion)
    end

    if not Game.GetScriptableServiceContainer():GetService("NativeInteractions") then
        table.insert(baseUI.requirementsIssues, "Redscript part of the mod is not installed")
    end

    if not ModArchiveExists("nativeInteractions.archive") then
        table.insert(baseUI.requirementsIssues, "Native Interactions archive is not installed")
    end

    if not requireCET(CETVersion) then
        table.insert(baseUI.requirementsIssues, "Cyber Engine Tweaks version is outdated, please update to at least " .. CETVersion)
    end
end

local function getWindowName()
    return ModName .. " " .. ModVersion .. "###Native Interactions 1.1.1" -- use fixed ID, pin it at 1.1.1 to avoid another window reset
end

function baseUI.draw(debug)
    if #baseUI.requirementsIssues > 0 then
        if ImGui.Begin(getWindowName(), ImGuiWindowFlags.AlwaysAutoResize) then
            style.mutedText("The following issues are preventing Native Interactions from running:")

            for _, issue in pairs(baseUI.requirementsIssues) do
                ImGui.Text(issue)
            end

            ImGui.End()
        end
        return
    end

    if ImGui.Begin(getWindowName(), ImGuiWindowFlags.AlwaysAutoResize) then
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

            if ImGui.BeginTabItem("Edit Removals") then
                ImGui.Spacing()
                baseUI.removalsUI.draw(debug)
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        ImGui.End()
    end
end

return baseUI