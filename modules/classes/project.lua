local config = require("modules/utils/config")
local utils = require("modules/utils/utils")

---Class for keeping project data
---@class project
---@field mod mod?
---@field name string
---@field interactions interaction[]
---@field enabled boolean
local project = {}

function project:new(mod)
	local o = {}

    o.mod = mod
    o.name = "Default Project"
    o.interactions = {}
    o.enabled = true

    self.__index = self
   	return setmetatable(o, self)
end

function project:load(data)
    for key, value in pairs(data) do
        self[key] = value
    end

    self.interactions = {}
    for _, interactionData in pairs(data.interactions) do
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

    self:save()
end

---@param interaction interaction
function project:removeInteraction(interaction)
    interaction:remove()
    utils.removeItem(self.interactions, interaction)
    self:save()
end

function project:sessionStart()
    for _, interaction in pairs(self.interactions) do
        interaction:sessionStart()
    end
end

function project:onUpdate()

end

function project:save()
    local data = {}

    data.name = self.name
    data.enabled = self.enabled
    data.interactions = {}
    for _, interaction in pairs(self.interactions) do
        table.insert(data.interactions, interaction:save())
    end

    config.saveFile(string.format("projects/%s.json", self.name), data)
end

return project