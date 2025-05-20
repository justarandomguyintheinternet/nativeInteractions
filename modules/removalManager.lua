local resourceHelper = require("modules/utils/resourceHelper")
local projectsManager = require("modules/projectsManager")
local utils = require("modules/utils/utils")

local data = {
    {
        name = "Glen Apartment",
        scene = "dlc\\dlc6_apart\\loc_dlc6_apart_hey_gle\\quest\\scenes\\dlc6_apart_hey_gle_interactions.scene",
        interactions = {
            ["glen_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["glen_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1691
            },
            ["glen_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["glen_coffee"] = {
                name = "Coffe Machine",
                nodeID = 1358
            },
            ["glen_mirror"] = {
                name = "Mirror",
                nodeID = 220
            },
            ["glen_billiard"] = {
                name = "Billard",
                nodeID = 1518
            },
            ["glen_vinyl"] = {
                name = "Vinyl",
                nodeID = 1229
            },
            ["glen_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            }
        }
    }
}

---@class removals
---@field public data table[]
---@field public mod mod?
local removals = {
    data = data,
    mod = nil
}

function removals.init(mod)
    removals.mod = mod
    removals.registerPatches()
end

local function getInteractionDataByKey(key)
    for _, scene in pairs(data) do
        for interactionKey, interaction in pairs(scene.interactions) do
            if interactionKey == key then
                return scene.scene, interaction
            end
        end
    end

    return nil, nil
end

function removals.getProjectsByRemoval(key, exclusion)
    local projects = {}

    for _, project in pairs(projectsManager.projects) do
        if project ~= exclusion then
            for entryKey, _ in pairs(project.removals) do
                if entryKey == key then
                    table.insert(projects, project)
                    break
                end
            end
        end
    end

    return projects
end

function removals.registerPatches()
    for _, entry in pairs(data) do
        resourceHelper.patches[entry.scene] = {
            removals = {}
        }
    end

    for _, project in pairs(projectsManager.projects) do
        for key, _ in pairs(project.removals) do
            local scene, interaction = getInteractionDataByKey(key)

            if interaction and not utils.has_value(resourceHelper.patches[scene].removals, interaction.nodeID) then
                table.insert(resourceHelper.patches[scene].removals, interaction.nodeID)
            end
        end
    end
end

return removals