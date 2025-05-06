local world = {
    interactions = {}
}

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

    table.insert(world.interactions, data)
    return #world.interactions
end

function world.removeInteraction(key)
    if world.interactions[key] then
        if world.interactions[key].pinID then
            Game.GetMappinSystem():UnregisterMappin(world.interactions[key].pinID)
        end

        world.interactions[key] = nil
    end
end

function world.disableInteraction(key, state)
    if not world.interactions[key] then return end
    if world.interactions[key].disabled == state then return end

    world.interactions[key].disabled = state

    if world.interactions[key].shown then
        world.togglePin(world.interactions[key], false)
    else
        world.togglePin(world.interactions[key], true)
    end
end

function world.init()
    ObserveAfter("BaseMappinBaseController", "UpdateRootState", function(this) -- Custom pin texture
        local mappin = this:GetMappin()
        if not mappin then return end

        local pos = mappin:GetWorldPosition()
        for _, interaction in pairs(world.interactions) do
            if Vector4.Distance(pos, interaction.pos) < 0.05 and interaction.pinID ~= nil then
                local record = TweakDBInterface.GetUIIconRecord(interaction.icon)
                this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
                this.iconWidget:SetTexturePart(record:AtlasPartName())
                this.iconWidget:SetTintColor(interaction.iconColor or HDRColor.new({ Red = 0.15829999744892, Green = 1.3033000230789, Blue = 1.4141999483109, Alpha = 1.0 }))
                -- TODO: Bind to style
            end
        end
    end)
end

function world.update()
    if Game.GetQuestsSystem():GetFact("nif_scene_active") == 1 then return end -- Dont update if a scene is running

    local showInteractions = {} -- Aggregate all callbacks, make sure only one interaction per modulePath is active

    local posPlayer = GetPlayer():GetWorldPosition()
    local playerForward = GetPlayer():GetWorldForward()
    posPlayer.z = posPlayer.z + 1

    for key, interaction in pairs(world.interactions) do
        local update = interaction.shown
        local interactionAngle = 180 - Vector4.GetAngleBetween(playerForward, Vector4.new(posPlayer.x - interaction.pos.x, posPlayer.y - interaction.pos.y, posPlayer.z - interaction.pos.z, 0))

        if Vector4.Distance(posPlayer, interaction.pos) < interaction.interactionRange then -- Custom callback when in range and look at
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
        else
            interaction.shown = update
            interaction.callback(interaction.shown)
        end

        if not interaction.disabled and interaction.icon and Vector4.Distance(posPlayer, interaction.pos) < interaction.iconRange then -- Hide / show optional icon
            world.togglePin(interaction, true)
        elseif interaction.icon then
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
    if world.interactions[id] then
        world.interactions[id].pos = position
        if world.interactions[id].pinID then
            Game.GetMappinSystem():SetMappinPosition(world.interactions[id].pinID, position)
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