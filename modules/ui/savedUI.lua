local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local style = require("modules/ui/style")
local manager = require("modules/projectsManager")

---@class savedUI
---@field filter string
---@field loadedFileName string
---@field mod mod?
---@field maxLoadedTextWidth number?
---@field maxSaveAsTextWidth number?
---@field newFileName string
---@field popup boolean
---@field deleteData project?
local savedUI = {
    filter = "",
    loadedFileName = "",
    mod = nil,
    popup = false,
    deleteData = nil,
    maxLoadedTextWidth = nil,
    maxSaveAsTextWidth = nil,
    newFileName = ""
}

function savedUI.drawLoaded()
    if not savedUI.mod.baseUI.editUI.project then
        style.mutedText("No project loaded.")
        return
    end

    if not savedUI.maxLoadedTextWidth then
        savedUI.maxLoadedTextWidth = utils.getTextMaxWidth({ "Name", "Interactions" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Name:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(savedUI.maxLoadedTextWidth)
    savedUI.loadedFileName, _ = ImGui.InputTextWithHint('##Name', 'Name...', savedUI.loadedFileName, 40)
    if ImGui.IsItemDeactivatedAfterEdit() then
        local currentProject = savedUI.mod.baseUI.editUI.project

        if savedUI.loadedFileName ~= "" then
            savedUI.loadedFileName = utils.createFileName(savedUI.loadedFileName)
            os.rename("projects/" .. currentProject.name .. ".json", "projects/" .. savedUI.loadedFileName .. ".json")
            currentProject.name = savedUI.loadedFileName
            currentProject:save()
        else
            savedUI.loadedFileName = currentProject.name
        end
    end

    style.mutedText("Interactions:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(savedUI.maxLoadedTextWidth)
    ImGui.Text(tostring(#savedUI.mod.baseUI.editUI.project.interactions))
end

function savedUI.drawCreateNew()
    style.setNextItemWidth(250)
    savedUI.newFileName, _ = ImGui.InputTextWithHint('##newName', 'Project Name...', savedUI.newFileName, 40)
    ImGui.SameLine()

    style.pushButtonNoBG(true)
    style.pushGreyedOut(savedUI.newFileName == "")
    if ImGui.Button(IconGlyphs.ContentSaveOutline) and savedUI.newFileName ~= "" then
        savedUI.newFileName = utils.createFileName(savedUI.newFileName)

        local new = require("modules/classes/project"):new(savedUI.mod)
        new.name = savedUI.newFileName
        new:save()
        manager.addProject(new)
        savedUI.mod.baseUI.editUI.project = new
        savedUI.loadedFileName = savedUI.newFileName

        savedUI.newFileName = ""
    end
    style.popGreyedOut(savedUI.newFileName == "")
    style.pushButtonNoBG(false)
end

function savedUI.draw(mod)
    if not savedUI.mod then
        savedUI.mod = mod
    end

    style.sectionHeaderStart("EDIT PROJECT", "Any changes are automatically saved.")
    savedUI.drawLoaded()
    style.sectionHeaderEnd()

    style.sectionHeaderStart("NEW PROJECT", "Create and load a new project.")
    savedUI.drawCreateNew()
    style.sectionHeaderEnd()

    style.sectionHeaderStart("ALL PROJECTS", "Load or delete saved projects.")

    style.setNextItemWidth(250)
    savedUI.filter, _ = ImGui.InputTextWithHint('##Filter', 'Search for data...', savedUI.filter, 100)

    if savedUI.filter ~= '' then
        ImGui.SameLine()

        style.pushButtonNoBG(true)
        if ImGui.Button(IconGlyphs.Close) then
            savedUI.filter = ''
        end
        style.pushButtonNoBG(false)
    end

    ImGui.BeginChild("savedUI", -1, 7 * ImGui.GetFrameHeightWithSpacing())

    for _, project in pairs(manager.projects) do
        if (project.name:lower():match(savedUI.filter:lower())) ~= nil then
            ImGui.PushID(project.name)

            style.pushButtonNoBG(true)

            if ImGui.Button(IconGlyphs.TrayArrowDown) then
                savedUI.mod.baseUI.editUI.project = project
                savedUI.mod.baseUI.removalsUI.project = project
                savedUI.loadedFileName = project.name
                savedUI.mod.baseUI.switchToEdit = true
                savedUI.mod.baseUI.interactionUI.projectUnload()
            end
            style.tooltip("Load project")
            ImGui.SameLine()
            if ImGui.Button(IconGlyphs.Delete) then
                savedUI.popup = true
                savedUI.deleteData = project
            end
            style.tooltip("Delete project")
            ImGui.SameLine()
            ImGui.Text(project.name)

            style.pushButtonNoBG(false)

            ImGui.PopID()
        end
    end

    ImGui.EndChild()

    style.sectionHeaderEnd()

    savedUI.handlePopUp()
end

function savedUI.handlePopUp()
    if savedUI.popup then
        ImGui.OpenPopup("Delete Project?")
        if ImGui.BeginPopupModal("Delete Project?", true, ImGuiWindowFlags.AlwaysAutoResize) then
            if ImGui.Button("Cancel") then
                ImGui.CloseCurrentPopup()
                savedUI.popup = false
            end

            ImGui.SameLine()

            if ImGui.Button("Confirm") then
                ImGui.CloseCurrentPopup()
                savedUI.delete(savedUI.deleteData)
                savedUI.popup = false
            end
            ImGui.EndPopup()
        end
    end
end

function savedUI.delete(project)
    os.remove(string.format("projects/%s.json", project.name))

    if savedUI.mod.baseUI.editUI.project == project then
        savedUI.mod.baseUI.editUI.project = nil
        savedUI.mod.baseUI.removalsUI.project = nil
        savedUI.mod.baseUI.interactionUI.projectUnload()
    end

    manager.removeProject(project)
end

return savedUI