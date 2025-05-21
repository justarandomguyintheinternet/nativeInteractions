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
    },
    {
        name = "Northside Apartment",
        scene = "dlc\\dlc6_apart\\loc_dlc6_apart_wat_nid\\quest\\scenes\\dlc6_apart_wat_nid_interactions.scene",
        interactions = {
            ["watson_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["watson_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1627
            },
            ["watson_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["watson_mirror"] = {
                name = "Mirror",
                nodeID = 220
            }
        }
    },
    {
        name = "Japantown Apartment",
        scene = "dlc\\dlc6_apart\\loc_dlc6_apart_wbr_jpn\\quest\\scenes\\dlc6_apart_wbr_jpn_interactions.scene",
        interactions = {
            ["japantown_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["japantown_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 2095
            },
            ["japantown_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["japantown_mirror"] = {
                name = "Mirror",
                nodeID = 220
            },
            ["japantown_vinyl"] = {
                name = "Vinyl",
                nodeID = 1229
            },
            ["japantown_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            },
            ["japantown_incense"] = {
                name = "Incense",
                nodeID = 1853
            },
            ["japantown_guitar"] = {
                name = "Guitar",
                nodeID = 1401
            },
            ["japantown_bar"] = {
                name = "Sit Bar",
                nodeID = 1774
            }
        }
    },
    {
        name = "Corpo Plaza Apartment",
        scene = "dlc\\dlc6_apart\\loc_dlc6_apart_cct_dtn\\quest\\scenes\\dlc6_apart_cct_dtn_interactions.scene",
        interactions = {
            ["plaza_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["plaza_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 2065
            },
            ["plaza_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["plaza_mirror"] = {
                name = "Mirror",
                nodeID = 220
            },
            ["plaza_vinyl"] = {
                name = "Vinyl",
                nodeID = 1229
            },
            ["plaza_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            },
            ["plaza_coffee"] = {
                name = "Coffee Maker",
                nodeID = 1358
            },
            ["plaza_tea"] = {
                name = "Tea",
                nodeID = 1777
            },
            ["plaza_bar"] = {
                name = "Sit Bar",
                nodeID = 1733
            }
        }
    },
    {
        name = "H10 Apartment",
        scene = "base\\quest\\minor_quests\\mq000\\scenes\\mq000_01_apartment.scene",
        interactions = {
            ["h10_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["h10_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1339
            },
            ["h10_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["h10_mirror"] = {
                name = "Mirror",
                nodeID = 220
            },
            ["h10_sit"] = {
                name = "Couch Sit and TV",
                nodeID = 328
            }
        }
    },
    {
        name = "Judy Apartment",
        scene = "dlc\\dlc6_apart\\scenes\\dlc6_apart_judy_apartment_interactions.scene",
        interactions = {
            ["judy_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["judy_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1786
            },
            ["judy_shower"] = {
                name = "Shower",
                nodeID = 1651
            },
            ["judy_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            },
            ["judy_bar"] = {
                name = "Bar Sit",
                nodeID = 1616
            }
        }
    },
    {
        name = "Kerry Villa",
        scene = "dlc\\dlc6_apart\\scenes\\dlc6_apart_kerry_villa_interactions.scene",
        interactions = {
            ["kerry_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["kerry_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1739
            },
            ["kerry_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["kerry_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            },
            ["kerry_bar"] = {
                name = "Vinyl",
                nodeID = 1229
            },
            ["kerry_bedroom_sit"] = {
                name = "Sit Bedroom",
                nodeID = 1616
            }
        }
    },
    {
        name = "Panam Camp",
        scene = "dlc\\dlc6_apart\\scenes\\dlc6_apart_panam_camp_interactions.scene",
        interactions = {
            ["panam_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["panam_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1677
            },
            ["panam_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["panam_sit"] = {
                name = "Chair Sit",
                nodeID = 4
            },
            ["panam_mirror"] = {
                name = "Mirror",
                nodeID = 4,
                sceneOverride = "base\\open_world\\scenes\\mirrors\\mirror_scene_new_nomad_camp.scene"
            }
        }
    },
    {
        name = "River Trailer",
        scene = "dlc\\dlc6_apart\\scenes\\dlc6_apart_river_trailer_interactions.scene",
        interactions = {
            ["river_bed"] = {
                name = "Bed",
                nodeID = 6
            },
            ["river_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 1571
            },
            ["river_shower"] = {
                name = "Shower",
                nodeID = 47
            },
            ["river_sit"] = {
                name = "Couch Sit",
                nodeID = 4
            }
        }
    },
    {
        name = "Dogtown Safehouse",
        scene = "ep1\\quest\\minor_quests\\mq300\\scenes\\mq300_safehouse_interactions.scene",
        interactions = {
            ["dogtown_bed"] = {
                name = "Bed",
                nodeID = 10
            },
            ["dogtown_mirror"] = {
                name = "Mirror",
                nodeID = 58
            },
            ["dogtown_wardrobe"] = {
                name = "Wardrobe",
                nodeID = 331
            },
            ["dogtown_shower"] = {
                name = "Shower",
                nodeID = 347
            },
            ["dogtown_lean"] = {
                name = "Lean and Smoke",
                nodeID = 419
            },
            ["dogtown_meditate"] = {
                name = "Meditate",
                nodeID = 468
            },
            ["dogtown_dance"] = {
                name = "Dance",
                nodeID = 521
            },
            ["dogtown_sit"] = {
                name = "Chair Sit",
                nodeID = 454
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
                return interaction.sceneOverride or scene.scene, interaction
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

        for _, interaction in pairs(entry.interactions) do
            if interaction.sceneOverride then
                resourceHelper.patches[interaction.sceneOverride] = {
                    removals = {}
                }
            end
        end
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