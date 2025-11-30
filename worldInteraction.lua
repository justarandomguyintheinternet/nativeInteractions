local utils = require("modules/utils/utils")

-- OPTIMIZATION: Reverse Lookup Table
-- Allows us to find an interaction by its Pin ID instantly, without looping.
local pinLookup = {} 

-- OPTIMIZATION: Grid System Variables
local searchGrid = nil
local gridSize = 80.0 -- 80m chunks

local world = {
    interactions = {}
}

function world.addInteraction(modulePath, position, interactionRange, angle, icon, iconRange, iconColor, callback)
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
    
    -- Invalidate the grid so it rebuilds on the next update
    searchGrid = nil 
    
    return #world.interactions
end

function world.removeInteraction(key)
    if world.interactions[key] then
        local pinID = world.interactions[key].pinID
        if pinID then
            Game.GetMappinSystem():UnregisterMappin(pinID)
            -- Remove from lookup
            pinLookup[pinID.hash] = nil 
        end

        world.interactions[key] = nil
        searchGrid = nil -- Invalidate grid
    end
end

function world.disableInteraction(key, state)
    if not world.interactions[key] then return end
    world.interactions[key].disabled = state
end

function world.init()
    TweakDB:CloneRecord("WorldMappinUIProfile.nif", "WorldMappinUIProfile.Default")
    TweakDB:SetFlat("WorldMappinUIProfile.nif.visibleInTier", { true, true, true, false, false })

    -- CRITICAL OPTIMIZATION: Removed the loop (O(n)) and replaced with Hash Lookup (O(1))
    ObserveAfter("BaseMappinBaseController", "UpdateRootState", function(this)
        local mappin = this:GetMappin()
        if not mappin then return end

        -- INSTANT CHECK: Is this mappin one of ours?
        -- We check the ID hash directly. Zero math, zero looping.
        local interaction = pinLookup[mappin:GetID().hash]
        
        if interaction then
            local record = TweakDBInterface.GetUIIconRecord(interaction.icon)
            this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
            this.iconWidget:SetTexturePart(record:AtlasPartName())
            this.iconWidget:SetTintColor(interaction.iconColor or HDRColor.new({ Red = 0.15829999744892, Green = 1.3033000230789, Blue = 1.4141999483109, Alpha = 1.0 }))
        end
    end)

    Override("NativeInteractions", "IsCustomMappin", function (_, mappin)
        if mappin then
            -- INSTANT CHECK
            if pinLookup[mappin:GetID().hash] then
                return true
            end
        end
        return false
    end)
end

function world.update()
    -- 1. Early Exit
    if Game.GetQuestsSystem():GetFactStr("nif_scene_active") == 1 then return end

    local showInteractions = {} 

    -- 2. Cache Player Position
    local posPlayer = GetPlayer():GetWorldPosition()
    local playerForward = GetPlayer():GetWorldForward()
    posPlayer.z = posPlayer.z + 1

    -- 3. Pre-calculate lookup variables
    local Vector4_GetAngleBetween = Vector4.GetAngleBetween
    local Vector4_new = Vector4.new

    -- ==========================================
    -- PHASE A: ONE-TIME GRID BUILDING
    -- We sort all items into buckets once.
    -- ==========================================
    if not searchGrid then
        searchGrid = {}
        for _, interaction in pairs(world.interactions) do
             if interaction.pos then
                 local gx = math.floor(interaction.pos.x / gridSize)
                 local gy = math.floor(interaction.pos.y / gridSize)
                 local key = gx .. "_" .. gy
                 
                 if not searchGrid[key] then searchGrid[key] = {} end
                 table.insert(searchGrid[key], interaction)
             end
        end
    end

    -- ==========================================
    -- PHASE B: SELECTIVE SCANNING
    -- We find the player's bucket and only check neighbors.
    -- ==========================================
    local px = math.floor(posPlayer.x / gridSize)
    local py = math.floor(posPlayer.y / gridSize)

    -- Scan 3x3 Grid Area
    for x = px - 1, px + 1 do
        for y = py - 1, py + 1 do
            local bucketKey = x .. "_" .. y
            local bucket = searchGrid[bucketKey]
            
            if bucket then
                for _, interaction in pairs(bucket) do
                    -- [OPTIMIZED MATH LOGIC]
                    local update = interaction.shown
                    local interactionAngle = 360

                    local dx = posPlayer.x - interaction.pos.x
                    local dy = posPlayer.y - interaction.pos.y
                    local dz = posPlayer.z - interaction.pos.z
                    
                    local distSq = (dx * dx) + (dy * dy) + (dz * dz)
                    local iRangeSq = interaction.interactionRange * interaction.interactionRange
                    local iconRangeSq = interaction.iconRange * interaction.iconRange

                    if distSq < iRangeSq then
                        interactionAngle = 180 - Vector4_GetAngleBetween(playerForward, Vector4_new(dx, dy, dz, 0))
                        if interactionAngle < interaction.angle then
                            update = true and not interaction.disabled
                        else
                            update = false
                        end
                    else
                        update = false
                    end

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

                    if not interaction.disabled and interaction.icon and distSq < iconRangeSq then
                        if not interaction.pinID then
                            world.togglePin(interaction, true)
                        end
                    elseif interaction.pinID and interaction.icon then
                        world.togglePin(interaction, false)
                    end
                end
            end
        end
    end

    for _, data in pairs(showInteractions) do
        data.interaction.callback(data.interaction.shown)
    end
end

function world.forceIcons()
    for _, interaction in pairs(world.interactions) do
        if interaction.pinID then
            -- Clean up old ID from lookup
            pinLookup[interaction.pinID.hash] = nil
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
            
            local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
            interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
            
            -- Add new ID to lookup
            pinLookup[interaction.pinID.hash] = interaction
        end
    end
end

function world.togglePin(interaction, state)
    if not interaction.icon or interaction.hideIcon then return end

    if not state and interaction.pinID then
        -- Clean up lookup
        pinLookup[interaction.pinID.hash] = nil
        
        Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        interaction.pinID = nil
    elseif not interaction.pinID and state then
        local data = MappinData.new({ mappinType = 'Mappins.DefaultStaticMappin', variant = gamedataMappinVariant.UseVariant, visibleThroughWalls = false })
        interaction.pinID = Game.GetMappinSystem():RegisterMappin(data, interaction.pos)
        
        -- Add to lookup
        pinLookup[interaction.pinID.hash] = interaction
    end
end

function world.updateInteractionPosition(id, position)
    if world.interactions[id] then
        world.interactions[id].pos = position
        if world.interactions[id].pinID then
            Game.GetMappinSystem():SetMappinPosition(world.interactions[id].pinID, position)
        end
        -- Invalidate grid if things move
        searchGrid = nil
    end
end

function world.onSessionStart()
    for _, interaction in pairs(world.interactions) do
        interaction.shown = false
        interaction.pinID = nil
    end
    -- Clear lookups
    pinLookup = {}
    searchGrid = nil
end

function world.shutdown()
    for _, interaction in pairs(world.interactions) do
        if interaction.pinID then
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        end
    end
    pinLookup = {}
end

return world