local utils = require("modules/utils/utils")

local helper = {
    patches = {},
    endEvents = {}
}

function helper.init()
    Observe('PlayerPuppet', 'OnNIFSceneEvent', function (_, event)
        if helper.endEvents[event.eventAction.value] then
            helper.endEvents[event.eventAction.value]()
            helper.endEvents[event.eventAction.value] = nil
            Game.GetQuestsSystem():SetFact("nif_scene_active", 0)
        end
    end)

    Observe('NativeInteractions', 'ProcessScene', function(_, event)
        local path = ResRef.FromHash(event:GetPath():GetHash()):ToString()
        if not helper.patches[path] then return end

        local scene = event:GetResource()

        -- Patch nodeIDs of choice hubs
        local choiceIDs = {}
        local graph = scene.sceneGraph.graph

        for _, node in pairs(graph) do
            if node:IsA("scnChoiceNode") then
                table.insert(choiceIDs, node.nodeId.id)
                node.nodeId = scnNodeId.new({ id = node.nodeId.id + helper.patches[path].choiceID }) --node.nodeId.id + helper.patches[path].choiceID
            end
        end

        table.sort(graph, function (a, b)
            return a.nodeId.id < b.nodeId.id
        end)
        scene.sceneGraph.graph = graph

        -- Patch destination nodeIDs of nodes connected to choiceHubs
        for _, node in pairs(scene.sceneGraph.graph) do
            local sockets = node.outputSockets

            for _, socket in pairs(sockets) do
                local destinations = socket.destinations

                for key, destination in pairs(destinations) do
                    if utils.has_value(choiceIDs, destination.nodeId.id) then
                        destinations[key].nodeId = scnNodeId.new({ id = destination.nodeId.id + helper.patches[path].choiceID }) --destination.nodeId.id + helper.patches[path].choiceID
                    end
                end

                socket.destinations = destinations
            end

            node.outputSockets = sockets
        end

        -- Patch animation offsets
        if helper.patches[path].animationPosition and helper.patches[path].animationRotation then
            for _, node in pairs(scene.sceneGraph.graph) do
                if node:IsA("scnSectionNode") then
                    for _, event in pairs(node.events) do
                        if event:IsA("scnPlaySkAnimEvent") then
                            local data = event.rootMotionData
                            -- Some animation events have an offset defined in the scene file, so use that additionally
                            local pos = utils.addVector(helper.patches[path].animationPosition, helper.patches[path].animationRotation:ToQuat():Transform(data.originOffset:GetPosition()))
                            local rot = utils.addEuler(helper.patches[path].animationRotation, data.originOffset:GetOrientation():ToEulerAngles())
                            data.originOffset = Transform.new({ position = pos, orientation = rot:ToQuat() })
                            event.rootMotionData = data
                        end
                    end
                end
            end

            local workspots = scene.workspotInstances
            for _, workspot in pairs(workspots) do
                local pos = utils.addVector(helper.patches[path].animationPosition, helper.patches[path].animationRotation:ToQuat():Transform(workspot.localTransform:GetPosition()))
                local rot = utils.addEuler(helper.patches[path].animationRotation, workspot.localTransform:GetOrientation():ToEulerAngles())
                workspot.localTransform = Transform.new({ position = pos, orientation = rot:ToQuat() })
            end
            scene.workspotInstances = workspots
        end

        if helper.patches[path].propMap then
            -- NodeRefs in props
            local props = scene.props
            for _, prop in pairs(props) do
                local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(prop.findEntityInNodeParams.nodeRef)]

                if replacement then
                    local params = prop.findEntityInNodeParams
                    params.nodeRef = CreateNodeRef(replacement)
                    prop.findEntityInNodeParams = params
                end
            end
            scene.props = props

            -- NodeRefs in VFX events
            for _, node in pairs(scene.sceneGraph.graph) do
                if node:IsA("scnSectionNode") then
                    for _, event in pairs(node.events) do
                        if event:IsA("scneventsVFXEvent") then
                            local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(event.nodeRef)]

                            if replacement then
                                event.nodeRef = CreateNodeRef(replacement)
                            end
                        end
                    end
                end
            end

            -- Not really needed
            local performers = scene.debugSymbols.performersDebugSymbols
            for _, performer in pairs(performers) do
                local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(performer.entityRef.reference)]

                if replacement then
                    local entityRef = performer.entityRef
                    entityRef.reference = CreateNodeRef(replacement)
                    performer.entityRef = entityRef
                end
            end
            scene.debugSymbols.performersDebugSymbols = performers
        end
    end)
end

function helper.registerPatch(scenePath, patchData)
    helper.patches[scenePath] = patchData
end

function helper.registerSceneEnd(eventName, callback)
    if helper.endEvents[eventName] then
        print("[NativeInteractions] Scene end event already registered: " .. eventName)
        return false
    end

    helper.endEvents[eventName] = callback

    return true
end

return helper