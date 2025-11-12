local manager = require("modules/projectsManager")

---@class api
local api = {}

function api.init()
    Observe('NativeInteractions', 'ToggleProject', function(_, project, state)
        api.toggleProject(project, state)
    end)

    Observe('NativeInteractions', 'ToggleAll', function(_, state)
        api.toggleAll(state)
    end)
end

function api.toggleProject(projectName, state)
    for _, project in pairs(manager.projects) do
        if project.name == projectName then
            if state then
                project:enable()
            else
                project:disable()
            end
        end
    end
end

function api.toggleAll(state)
    for _, project in pairs(manager.projects) do
        if state then
            project:enable()
        else
            project:disable()
        end
    end
end

return api