local config = require("modules/utils/config")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local manager = require("modules/projectsManager")

---Class for keeping project data
---@class project
---@field mod mod?
---@field name string
---@field interactions interaction[]
---@field removals table
---@field enabled boolean
local project = {}

function project:new(mod)
	local o = {}

    o.mod = mod
    o.name = "Default Project"
    o.interactions = {}
    o.removals = {}
    o.enabled = true

    self.__index = self
   	return setmetatable(o, self)
end

function project:load(data)
    for key, value in pairs(data) do
        self[key] = value
    end

    self.interactions = {}
    for _, interactionData in pairs(data.interactions or {}) do
        local interaction = require(string.format("modules/classes/%s", interactionData.modulePath)):new(self.mod, self)
        interaction:load(interactionData)
        table.insert(self.interactions, interaction)
    end
end

---@param interaction interaction
---@param name string
function project:addInteraction(interaction, name)
    local iconPosition = GetPlayer():GetWorldPosition()
    iconPosition.z = iconPosition.z + 0.5

    interaction:load({ name = name, worldIconPosition = utils.fromVector(iconPosition) })
    table.insert(self.interactions, interaction)

    table.sort(self.interactions, function(a, b)
        return a.modulePath < b.modulePath
    end)

    manager.rebuildUpdateList()
    self:save()
end

---@param interaction interaction
function project:removeInteraction(interaction)
    interaction:remove()
    utils.removeItem(self.interactions, interaction)
    manager.rebuildUpdateList()
    self:save()
end

function project:sessionStart()
    for _, interaction in pairs(self.interactions) do
        interaction:resetSceneState()
        interaction:sessionStart()
    end
end

function project:sessionEnd()
    for _, interaction in pairs(self.interactions) do
        interaction:sessionEnd()
    end
end

function project:enable()
    if self.enabled then return end

    self.enabled = true
    manager.rebuildUpdateList()

    for _, interaction in pairs(self.interactions) do
        world.disableInteraction(interaction.worldInteractionID, false)
        interaction:sessionStart() -- Needed so that apartment can potentially disable itself
    end
end

function project:disable()
    if not self.enabled then return end

    self.enabled = false
    manager.rebuildUpdateList()

    for _, interaction in pairs(self.interactions) do
        -- The editor UI stops drawing a disabled project, so end any ongoing edit instead of leaking its preview entity
        interaction:editEnd()
        interaction:sessionEnd()
        world.disableInteraction(interaction.worldInteractionID, true)
    end
end

function project:save()
    local data = {}

    data.name = self.name
    data.interactions = {}
    for _, interaction in pairs(self.interactions) do
        table.insert(data.interactions, interaction:save())
    end
    data.removals = utils.deepcopy(self.removals)

    config.saveFile(string.format("projects/%s.json", self.name), data)
end

return project