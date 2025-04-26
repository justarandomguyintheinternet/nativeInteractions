local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local Cron = require("modules/utils/Cron")

---Class for base placed interaction
---@class interaction
---@field mod mod?
---@field project project?
---@field interactionType string
---@field modulePath string
---@field scene string
---@field skipFact string
---@field endEvent string
---@field startFactID number
---@field name string
---@field worldIcon string
---@field worldIconRange number
---@field interactionAngle number
---@field interactionRange number
---@field editorIcon string
---@field sceneRunning boolean
---@field worldInteractionID number?
---@field worldIconPosition {x: number, y: number, z: number}?
---@field choiceUniqueID number
local interaction = {}

function interaction:new(mod, project)
	local o = {}

    o.mod = mod
    o.project = project
    o.interactionType = "Base Interaction"
    o.modulePath = "interaction"
    o.scene = "quest\\wardrobe.scene"
    o.skipFact = "nif_skip_wardrobe"
    o.endEvent = "nif_exit_wardrobe"
    o.startFactID = 1

    o.name = "Default Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.RobotConfusedOutline

    o.sceneRunning = false
    o.worldInteractionID = nil

    o.worldIconPosition = nil
    o.choiceUniqueID = -1

    self.__index = self
   	return setmetatable(o, self)
end

function interaction:load(data)
    CName.add(self.skipFact)

    for key, value in pairs(data) do
        self[key] = value
    end

    if self.choiceUniqueID == -1 then
        self.choiceUniqueID = math.random(0, 4294967295 - 100000) -- 100k nodeIDs for base nodes
    end

    self.worldInteractionID = world.addInteraction(self.modulePath, ToVector4(self.worldIconPosition), self.interactionRange, self.interactionAngle, self.worldIcon, self.worldIconRange, nil, function (state)
        if state then
            self:start()
        else
            self:stop()
        end
    end)
end

function interaction:getPatchData()
    return { choiceID = self.choiceUniqueID }
end

function interaction:start()
    if self.sceneRunning then return end

    self.sceneRunning = true

    -- Delay this, so that if during the same tick another one stops, there is time for it to properly shutdown, before this one starts
    Cron.AfterTicks(2, function ()
        local success = resourceHelper.registerSceneEnd(self.endEvent, function ()
            self.sceneRunning = false
            print("Scene end")
        end)

        if not success then
            self.sceneRunning = false
            return
        end

        Game.GetResourceDepot():RemoveResourceFromCache(self.scene)
        resourceHelper.registerPatch(self.scene, self:getPatchData())
        Game.GetQuestsSystem():SetFact("nif_start_signal", 1)
        Game.GetQuestsSystem():SetFact("nif_interaction_id", self.startFactID)

        print("Start", self.name)
    end)
end

function interaction:stop()
    if not self.sceneRunning then return end

    self.sceneRunning = false
    print("Stop", self.name)
    Game.GetQuestsSystem():SetFact(self.skipFact, 1)
end

function interaction:remove()
    self:stop()
    self:editEnd()

    if self.worldInteractionID then
        world.removeInteraction(self.worldInteractionID)
        self.worldInteractionID = nil
    end
end

function interaction:sessionStart() end

function interaction:onUpdate() end

function interaction:draw() end

function interaction:editStart() end

function interaction:editEnd() end

function interaction:save()
    local data = {}

    data.name = self.name
    data.modulePath = self.modulePath
    data.worldIconRange = self.worldIconRange
    data.interactionAngle = self.interactionAngle
    data.interactionRange = self.interactionRange
    data.worldIconPosition = utils.deepcopy(self.worldIconPosition)
    data.choiceUniqueID = self.choiceUniqueID

    return data
end

return interaction