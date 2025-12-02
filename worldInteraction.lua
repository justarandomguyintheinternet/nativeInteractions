local utils = require("modules/utils/utils")

-- OPTIMIZATION 1: Grid System (For Logic)
local searchGrid = nil
local gridSize = 80.0 

-- OPTIMIZATION 2: UI Cache (For Visuals)
-- Stores the result of our check so we only do math ONCE per icon.
-- "__mode = 'k'" means it automatically cleans up memory when icons despawn.
local activeControllers = setmetatable({}, { __mode = "k" })

local world = {
    interactions = {}
}

-- HELPER: Rebuilds the optimization grid
function world.rebuildGrid()
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
    searchGrid = nil 
    return #world.interactions
end

function world.removeInteraction(key)
    if world.interactions[key] then
        local pinID = world.interactions[key].pinID
        if pinID then
            Game.GetMappinSystem():UnregisterMappin(pinID)
        end

        world.interactions[key] = nil
        searchGrid = nil
    end
end

function world.disableInteraction(key, state)
    if not world.interactions[key] then return end
    world.interactions[key].disabled = state
end

function world.init()
    TweakDB:CloneRecord("WorldMappinUIProfile.nif", "WorldMappinUIProfile.Default")
    TweakDB:SetFlat("WorldMappinUIProfile.nif.visibleInTier", { true, true, true, false, false })

    -- THE ULTIMATE FIX: Cached Identification
    ObserveAfter("BaseMappinBaseController", "UpdateRootState", function(this)
        
        -- 1. FAST LANE: Check if we have already seen this icon
        local cached = activeControllers[this]
        if cached then
            if cached == "ignore" then 
                return -- It's an enemy/grenade we already checked. STOP.
            else
                -- It is one of our chairs! Apply style instantly.
                local record = TweakDBInterface.GetUIIconRecord(cached.icon)
                this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
                this.iconWidget:SetTexturePart(record:AtlasPartName())
                this.iconWidget:SetTintColor(cached.iconColor or HDRColor.new({ Red = 0.15829999744892, Green = 1.3033000230789, Blue = 1.4141999483109, Alpha = 1.0 }))
                return
            end
        end

        -- 2. SLOW LANE: First time seeing this icon. Do the math ONCE.
        local mappin = this:GetMappin()
        if not mappin then return end

        local pos = mappin:GetWorldPosition()
        local foundInteraction = nil
        
        -- Ensure grid exists
        if not searchGrid then world.rebuildGrid() end
        
        -- Grid Optimization check
        if searchGrid and pos then
             local gx = math.floor(pos.x / gridSize)
             local gy = math.floor(pos.y / gridSize)
             local key = gx .. "_" .. gy
             local bucket = searchGrid[key]
             
             if bucket then
                 for _, interaction in pairs(bucket) do
                     if interaction.pinID then
                         -- Squared Distance Check (Tolerance 0.05)
                         local dx = pos.x - interaction.pos.x
                         local dy = pos.y - interaction.pos.y
                         local dz = pos.z - interaction.pos.z
                         local distSq = dx*dx + dy*dy + dz*dz
                         
                         if distSq < 0.0025 then 
                             foundInteraction = interaction
                             break 
                         end
                     end
                 end
             end
        end

        -- 3. CACHE THE RESULT
        if foundInteraction then
            activeControllers[this] = foundInteraction -- Remember this is a chair
            
            -- Apply style immediately for this first frame
            local record = TweakDBInterface.GetUIIconRecord(foundInteraction.icon)
            this.iconWidget:SetAtlasResource(record:AtlasResourcePath())
            this.iconWidget:SetTexturePart(record:AtlasPartName())
            this.iconWidget:SetTintColor(foundInteraction.iconColor or HDRColor.new({ Red = 0.15829999744892, Green = 1.3033000230789, Blue = 1.4141999483109, Alpha = 1.0 }))
        else
            activeControllers[this] = "ignore" -- Remember this is NOT a chair
        end
    end)

    Override("NativeInteractions", "IsCustomMappin", function (_, mappin)
        if mappin then
            -- We can't use the controller cache here (no 'this'), 
            -- but this function runs much less frequently than UpdateRootState.
            -- We use the Grid Optimization here to keep it fast.
            local pos = mappin:GetWorldPosition()
            
            if not searchGrid then world.rebuildGrid() end
            
            if searchGrid and pos then
                 local gx = math.floor(pos.x / gridSize)
                 local gy = math.floor(pos.y / gridSize)
                 local key = gx .. "_" .. gy
                 local bucket = searchGrid[key]
                 if bucket then
                     for _, interaction in pairs(bucket) do
                         if interaction.pinID then
                             local dx = pos.x - interaction.pos.x
                             local dy = pos.y - interaction.pos.y
                             local dz = pos.z - interaction.pos.z
                             if (dx*dx + dy*dy + dz*dz) < 0.0025 then
                                 return true
                             end
                         end
                     end
                 end
            end
        end
        return false
    end)
end

function world.update()
    -- 1. Early Exit
    if Game.GetQuestsSystem():GetFactStr("nif_scene_active") == 1 then return end

    -- 2. Cache Player Position
    local posPlayer = GetPlayer():GetWorldPosition()
    local playerForward = GetPlayer():GetWorldForward()
    posPlayer.z = posPlayer.z + 1

    -- 3. Cache Math
    local Vector4_GetAngleBetween = Vector4.GetAngleBetween
    local Vector4_new = Vector4.new

    -- 4. Grid Check
    if not searchGrid then world.rebuildGrid() end

    -- 5. Selective Scanning (3x3 Area)
    local px = math.floor(posPlayer.x / gridSize)
    local py = math.floor(posPlayer.y / gridSize)
    local showInteractions = {} 

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
        searchGrid = nil
    end
end

function world.onSessionStart()
    for _, interaction in pairs(world.interactions) do
        interaction.shown = false
        interaction.pinID = nil
    end
    searchGrid = nil
    activeControllers = setmetatable({}, { __mode = "k" }) -- Clear cache
end

function world.shutdown()
    for _, interaction in pairs(world.interactions) do
        if interaction.pinID then
            Game.GetMappinSystem():UnregisterMappin(interaction.pinID)
        end
    end
end

return world