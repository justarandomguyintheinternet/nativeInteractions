local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

---@class manager
---@field projects project[]
---@field updateList interaction[]
---@field mod mod?
local manager = {
    projects = {},
    updateList = {},
    mod = nil
}

function manager.init(mod)
    manager.mod = mod

    for _, file in pairs(dir("projects")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local entry = require("modules/classes/project"):new(mod)
            entry:load(config.loadFile(string.format("projects/%s", file.name)))
            table.insert(manager.projects, entry)
        end
    end

    manager.rebuildUpdateList()
end

---Rebuilds the list of interactions on which onUpdate is called
function manager.rebuildUpdateList()
    local list = {}

    for _, project in pairs(manager.projects) do
        if project.enabled then
            for _, interaction in pairs(project.interactions) do
                if interaction.needsUpdate then
                    table.insert(list, interaction)
                end
            end
        end
    end

    manager.updateList = list
end

local playerPosition = { x = 0, y = 0, z = 0 }

function manager.update()
    local list = manager.updateList
    local nUpdates = #list
    if nUpdates == 0 then return end

    local position = GetPlayer():GetWorldPosition()
    playerPosition.x = position.x
    playerPosition.y = position.y
    playerPosition.z = position.z

    for i = 1, nUpdates do
        list[i]:onUpdate(playerPosition)
    end
end

function manager.sessionStart()
    for _, project in pairs(manager.projects) do
        project:sessionStart()
    end
end

function manager.sessionEnd()
    for _, project in pairs(manager.projects) do
        project:sessionEnd()
    end
end

---@param name string
---@param ignore project?
---@return boolean
local function isNameTaken(name, ignore)
    if ignore and ignore.name == name then return false end

    for _, project in pairs(manager.projects) do
        if project ~= ignore and project.name == name then
            return true
        end
    end

    return false
end

---@param name string
---@param ignore project?
---@return string
function manager.getUniqueName(name, ignore)
    local unique = name
    local suffix = 1

    while isNameTaken(unique, ignore) do
        suffix = suffix + 1
        unique = string.format("%s_%d", name, suffix)
    end

    return unique
end

function manager.addProject(project)
    table.insert(manager.projects, project)
    manager.rebuildUpdateList()
end

---@param data project
function manager.removeProject(data)
    for _, interaction in pairs(data.interactions) do
        interaction:remove()
    end
    utils.removeItem(manager.projects, data)
    manager.rebuildUpdateList()
end

function manager.shutdown()
    for _, project in pairs(manager.projects) do
        for _, interaction in pairs(project.interactions) do
            interaction:remove()
        end
    end

    manager.updateList = {}
end

return manager