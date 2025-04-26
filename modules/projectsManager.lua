local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

---@class manager
---@field projects project[]
---@field mod mod?
local manager = {
    projects = {},
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
end

function manager.update()
    for _, project in pairs(manager.projects) do
        project:onUpdate()
    end
end

function manager.sessionStart()
    for _, project in pairs(manager.projects) do
        project:sessionStart()
    end
end

function manager.addProject(project)
    table.insert(manager.projects, project)
end

---@param data project
function manager.removeProject(data)
    for _, interaction in pairs(data.interactions) do
        interaction:remove()
    end
    utils.removeItem(manager.projects, data)
end

function manager.shutdown()
    for _, project in pairs(manager.projects) do
        for _, interaction in pairs(project.interactions) do
            interaction:remove()
        end
    end
end

return manager