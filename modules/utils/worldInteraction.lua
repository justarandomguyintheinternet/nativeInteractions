local utils = require("modules/utils/utils")

local cellSize = 25
local world = {
    interactions = {},
    searchGrid = {}
}

local function getGridKey(position)
    return math.floor(position.x / cellSize) .. "_" .. math.floor(position.y / cellSize)
end

function world.addInteraction(modulePath, position, interactionRange, angle, icon, iconRange, iconColor, callback) -- Add a in-world interaction with callback for hide / show, icon is optional
    local data = {
        modulePath = modulePath,
        pos = position,
        interactionRange = interactionRange,
        icon = icon,
        iconRange = iconRange,
        iconColor = iconColor,
        angle = angle,
        callback = callback,
        pinID = nil,
        shown = false,
        disabled = false,
        hideIcon = false
    }

    local key = getGridKey(position)

    if not world.searchGrid[key] then
        world.searchGrid[key] = {}
    end

    table.insert(world.interactions, data)
    table.insert(world.searchGrid[key], world.interactions[#world.interactions])

    return #world.interactions
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

        world.interactions[key] = nil
    end
end

function world.getGridInteractions(origin)
    local originX = math.floor(origin.x / cellSize)
    local originY = math.floor(origin.y / cellSize)
    local interactions = {}

    for x = -1, 1 do
        for y = -1, 1 do
            local key = (originX + x) .. "_" .. (originY + y)
            utils.combine(interactions, world.searchGrid[key] or {})
        end
    end

    return interactions
end

function world.disableInteraction(key, state)
    if not world.interactions[key] then return end

    world.interactions[key].disabled = state
end

function world.init()
    TweakDB:CloneRecord("WorldMappinUIProfile.nif", "WorldMappinUIProfile.Default")
    TweakDB:SetFlat("WorldMappinUIProfile.nif.visibleInTier", { true, true, true, false, false })

    ObserveAfter("BaseMappinBaseController", "UpdateRootState", function(this) -- Custom pin texture
        local mappin = this:GetMappin()
        if not mappin or this:GetProfile():GetID().value ~= "WorldMappinUIProfile.nif" then return end

        local pos = mappin:GetWorldPosition()
        for _, interaction in pairs(world.getGridInteractions(pos)) do
            if Vector4.Distance(pos, interaction.pos) < 0.05 and interaction.pinID ~= nil then
                local record = TweakDBInterface.GetUIIconRecord(interaction.icon)
                this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
                this.iconWidget:SetTexturePart(record:AtlasPartName())
                this.iconWidget:SetTintColor(interaction.iconColor or HDRColor.new({ Red = 0.15829999744892, Green = 1.3033000230789, Blue = 1.4141999483109, Alpha = 1.0 }))
                -- TODO: Bind to style
            end
        end
    end)

    Override("NativeInteractions", "IsCustomMappin", function (_, mappin)
        if mappin then
            local pos = mappin:GetWorldPosition()
            for _, interaction in pairs(world.getGridInteractions(pos)) do
                if Vector4.Distance(pos, interaction.pos) < 0.05 and interaction.pinID ~= nil then
                    return true
                end
            end
        end

        return false
    end)
end

function world.update()
    if Game.GetQuestsSystem():GetFactStr("nif_scene_active") == 1 then return end -- Dont update if a scene is running

    local showInteractions = {} -- Aggregate all callbacks, make sure only one interaction per modulePath is active

    local posPlayer = GetPlayer():GetWorldPosition()
    local playerForward = GetPlayer():GetWorldForward()
    posPlayer.z = posPlayer.z + 1

    for _, interaction in pairs(world.getGridInteractions(posPlayer)) do
        local update = interaction.shown
        local interactionAngle = 360

        if utils.vectorDistance(posPlayer, interaction.pos) < interaction.interactionRange then -- Custom callback when in range and look at
            interactionAngle = 180 - Vector4.GetAngleBetween(playerForward, Vector4.new(posPlayer.x - interaction.pos.x, posPlayer.y - interaction.pos.y, posPlayer.z - interaction.pos.z, 0))

            if interactionAngle < interaction.angle then
                update = true and not interaction.disabled
            else
                update = false
            end
        else
            update = false
        end

        -- Ensure only one per modulePath is active at a time
        if update then
            if not showInteractions[interaction.modulePath] then
                interaction.shown = true
                showInteractions[interaction.modulePath] = { angle = interactionAngle, interaction = interaction }
            elseif interactionAngle < showInteractions[interaction.modulePath].angle then
                showInteractions[interaction.modulePath].interaction.shown = false
                showInteractions[interaction.modulePath].interaction.callback(false)

                interaction.shown = true
                showInteractions[interaction.modulePath] = { angle = interactionAngle, interaction = interaction }
            else
                interaction.shown = false
                interaction.callback(false)
            end
        elseif interaction.shown then
            interaction.shown = update
            interaction.callback(interaction.shown)
        end

        if not interaction.disabled and interaction.icon and utils.vectorDistance(posPlayer, interaction.pos) < interaction.iconRange then -- Hide / show optional icon
            if not interaction.pinID then
                world.togglePin(interaction, true)
            end
        elseif interaction.pinID and interaction.icon then
            world.togglePin(interaction, false)
        end
    end

    for _, data in pairs(showInteractions) do
        data.interaction.callback(data.interaction.shown)
    end
end

--Fix to make sure all icons are visible, to fix bug where after a scene some would be missing
function world.forceIcons()
    for _, interaction in pairs(world.interactions) do
        if interaction.pinID then
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
            local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
            interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
        end
    end
end

function world.togglePin(interaction, state)
    if not interaction.icon or interaction.hideIcon then return end

    if not state and interaction.pinID then
        Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        interaction.pinID = nil
    elseif not interaction.pinID and state then
        local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
        interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
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
    for _, interaction in pairs(world.interactions) do
        interaction.shown = false
        interaction.pinID = nil
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