local utils = require("modules/utils/utils")
local ref = require("modules/utils/Ref")

local roundRobin = 0
local cellSize = 12

local world = {
    interactions = {},
    searchGrid = {},
    interactionCounter = 0,
    activeInteractions = {}, -- Currently shown interaction per modulePath, so that limiting to one interaction per modulePath is possible with roundRobin
    pinnedInteractions = {},
    cellSize = cellSize
}

local function getGridKey(position)
    return math.floor(position.x / cellSize) .. "_" .. math.floor(position.y / cellSize)
end

function world.addInteraction(modulePath, position, interactionRange, angle, icon, iconRange, iconColor, callback) -- Add a in-world interaction with callback for hide / show, icon is optional
    local data = {
        modulePath = modulePath,
        pos = position,
        interactionRange = interactionRange ^ 2,
        icon = icon,
        iconRange = iconRange ^ 2,
        iconColor = iconColor,
        angle = angle,
        callback = callback,
        pinID = nil,
        pinController = nil,
        shown = false,
        disabled = false
    }

    local key = getGridKey(position)

    if not world.searchGrid[key] then
        world.searchGrid[key] = {}
    end

    world.interactionCounter = world.interactionCounter + 1
    world.interactions[world.interactionCounter] = data
    table.insert(world.searchGrid[key], data)

    return world.interactionCounter
end

function world.removeInteraction(key)
    if world.interactions[key] then
        local data = world.interactions[key]
        local gridKey = getGridKey(data.pos)

        if world.searchGrid[gridKey] then
            utils.removeItem(world.searchGrid[gridKey], data)
        end

        if world.interactions[key].pinID then
            Game.GetMappinSystem():UnregisterMappin(world.interactions[key].pinID)
        end
        world.pinnedInteractions[data] = nil

        local active = world.activeInteractions[data.modulePath]
        if active and active.interaction == data then
            world.activeInteractions[data.modulePath] = nil
        end

        world.interactions[key] = nil
    end
end

function world.getGridInteractions(origin, singleCell, roundRobin)
    local singleCell = singleCell == nil and false or singleCell
    local originX = math.floor(origin.x / cellSize)
    local originY = math.floor(origin.y / cellSize)

    if singleCell then
        local key = originX .. "_" .. originY
        return world.searchGrid[key] or {}
    end

    if roundRobin then
        local x = roundRobin % 3 - 1
        local y = math.floor(roundRobin / 3) - 1
        local key = (originX + x) .. "_" .. (originY + y)
        return world.searchGrid[key] or {}
    end

    return {}
end

function world.disableInteraction(key, state)
    if not world.interactions[key] then return end

    world.interactions[key].disabled = state
end

function world.init()
    if TweakDB:GetRecord("WorldMappinUIProfile.nif") == nil then
        TweakDB:CloneRecord("WorldMappinUIProfile.nif", "WorldMappinUIProfile.Default")
        TweakDB:SetFlat("WorldMappinUIProfile.nif.visibleInTier", { true, true, true, false, false })
    end

    ObserveAfter("BaseMappinBaseController", "UpdateRootState", function(this) -- Custom pin texture
        local mappin = this:GetMappin()
        if not mappin or this:GetProfile():GetID().value ~= "WorldMappinUIProfile.nif" then return end

        local pos = mappin:GetWorldPosition()
        for _, interaction in pairs(world.getGridInteractions(pos, true)) do
            if interaction.pinID and interaction.pinID.value == this:GetMappin():GetNewMappinID().value then
                local record = TweakDBInterface.GetUIIconRecord(interaction.icon)
                this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
                this.iconWidget:SetTexturePart(record:AtlasPartName())

                if interaction.iconColor then
                    this.iconWidget:SetTintColor(HDRColor.new(interaction.iconColor))
                else
                    this.iconWidget.widget:BindProperty("tintColor", "MainColors.Blue")
                end
                interaction.pinController = ref.Weak(this)

                return
            end
        end
    end)

    Override("NativeInteractions", "IsCustomMappin", function (_, mappin)
        if mappin then
            local pos = mappin:GetWorldPosition()
            for _, interaction in pairs(world.getGridInteractions(pos, true)) do
                if interaction.pinID and interaction.pinID.value == mappin:GetNewMappinID().value then
                    return true
                end
            end
        end

        return false
    end)
end

---Returns whether the interaction should be shown, together with the look at angle and the squared distance
local function evaluateInteraction(interaction, posPlayer, playerForward)
    local playerInteractionDist = utils.vectorDistanceSquared(posPlayer, interaction.pos)

    if interaction.disabled or playerInteractionDist >= interaction.interactionRange then
        return false, 360, playerInteractionDist
    end

    local interactionAngle = 180 - Vector4.GetAngleBetween(playerForward, Vector4.new(posPlayer.x - interaction.pos.x, posPlayer.y - interaction.pos.y, posPlayer.z - interaction.pos.z, 0))

    return interactionAngle < interaction.angle, interactionAngle, playerInteractionDist
end

local function hideInteraction(interaction)
    local active = world.activeInteractions[interaction.modulePath]
    if active and active.interaction == interaction then
        world.activeInteractions[interaction.modulePath] = nil
    end

    if not interaction.shown then return end

    interaction.shown = false
    interaction.callback(false)
end

local function showInteraction(interaction, interactionAngle)
    local active = world.activeInteractions[interaction.modulePath]
    if active and active.interaction ~= interaction then
        hideInteraction(active.interaction)
    end

    interaction.shown = true
    world.activeInteractions[interaction.modulePath] = { angle = interactionAngle, interaction = interaction }
end

local function scanCell(cell, posPlayer, playerForward)
    for _, interaction in pairs(cell) do
        local show, interactionAngle, playerInteractionDist = evaluateInteraction(interaction, posPlayer, playerForward)
        local active = world.activeInteractions[interaction.modulePath]

        -- Ensure only one per modulePath is active at a time, the closest one to the crosshair wins
        if show and (not active or active.interaction == interaction or interactionAngle < active.angle) then
            showInteraction(interaction, interactionAngle)
        else
            hideInteraction(interaction)
        end

        -- Hiding is handled outside, based on pinnedInteractions table so that pins outside any cells can be hidden still
        if not interaction.disabled and interaction.icon and not interaction.pinID and playerInteractionDist < interaction.iconRange then
            world.togglePin(interaction, true)
        end
    end
end

function world.update()
    if Game.GetQuestsSystem():GetFactStr("nif_scene_active") == 1 then return end -- Dont update if a scene is running

    local posPlayer = GetPlayer():GetWorldPosition()
    local playerForward = GetPlayer():GetWorldForward()
    posPlayer.z = posPlayer.z + 1

    -- Re-check the active interactions
    for _, active in pairs(world.activeInteractions) do
        local show, interactionAngle = evaluateInteraction(active.interaction, posPlayer, playerForward)

        if show then
            active.angle = interactionAngle
        else
            hideInteraction(active.interaction)
        end
    end

    -- Hide distant pins, regardless of whether they are in a scanned cell or not
    for interaction, _ in pairs(world.pinnedInteractions) do
        if interaction.disabled or utils.vectorDistanceSquared(posPlayer, interaction.pos) >= interaction.iconRange then
            world.togglePin(interaction, false)
        end
    end

    scanCell(world.getGridInteractions(posPlayer, false, roundRobin), posPlayer, playerForward)

    roundRobin = roundRobin + 1
    if roundRobin >= 9 then
        roundRobin = 0
    end

    for _, active in pairs(world.activeInteractions) do
        active.interaction.callback(true)
    end
end

--Fix to make sure all icons are visible, to fix bug where after a scene some would be missing
function world.forceIcons()
    for interaction, _ in pairs(world.pinnedInteractions) do
        if interaction.pinID then
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
            local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
            interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
        end
    end
end

function world.togglePin(interaction, state)
    if not interaction.icon then return end

    if not state and interaction.pinID then
        Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        interaction.pinID = nil
        interaction.pinController = nil
        world.pinnedInteractions[interaction] = nil
    elseif not interaction.pinID and state then
        local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
        interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
        world.pinnedInteractions[interaction] = true
    end
end

function world.updateInteractionPosition(id, position)
    local data = world.interactions[id]
    if data then
        local oldKey = getGridKey(data.pos)
        local newKey = getGridKey(position)

        if oldKey ~= newKey then
            if world.searchGrid[oldKey] then
                utils.removeItem(world.searchGrid[oldKey], data)
            end

            if not world.searchGrid[newKey] then
                world.searchGrid[newKey] = {}
            end
            table.insert(world.searchGrid[newKey], data)
        end

        data.pos = position
        if data.pinID then
            Game.GetMappinSystem():SetMappinPosition(data.pinID, position)
        end
    end
end

function world.onSessionStart() -- Save loaded, all pins are gone
    world.activeInteractions = {}
    world.pinnedInteractions = {}

    for _, interaction in pairs(world.interactions) do
        interaction.shown = false
        interaction.pinID = nil
        interaction.pinController = nil
    end
end

function world.shutdown()
    for _, interaction in pairs(world.interactions) do
        if interaction.pinID then
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        end
    end
end

return world