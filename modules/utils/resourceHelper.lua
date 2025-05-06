local utils = require("modules/utils/utils")

local helper = {
    patches = {},
    endEvents = {}
}

function helper.init()
    Observe('PlayerPuppet', 'OnNIFSceneEvent', function (_, event)
        if helper.endEvents[event.eventAction.value] then
            helper.endEvents[event.eventAction.value](Game.GetQuestsSystem():GetFact("nif_scene_active"))
            helper.endEvents[event.eventAction.value] = nil
            Game.GetQuestsSystem():SetFact("nif_scene_active", 0)
        end
    end)

    Observe('NativeInteractions', 'ProcessScene', function(_, event)
        local path = ResRef.FromHash(event:GetPath():GetHash()):ToString()
        if not helper.patches[path] then return end

        local scene = event:GetResource()

        helper.patchChoiceNodes(scene, path)
        helper.patchOffsets(scene, path)
        helper.patchNodeRefs(scene, path)
    end)
end

-- Patch nodeIDs of choice hubs
function helper.patchChoiceNodes(scene, path)
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
end

function helper.patchOffsets(scene, path)
    if not helper.patches[path].animationPosition or not helper.patches[path].animationRotation then return end

    -- Patch animation offsets
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

function helper.patchNodeRefs(scene, path)
    if not helper.patches[path].propMap then return end

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

    -- NodeRefs graph
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

        if node:IsA("scnQuestNode") then
            if node.questNode and node.questNode.type then
                if node.questNode.type:IsA("questDeviceManager_NodeType") then
                    local params = node.questNode.type.params

                    for _, param in pairs(params) do
                        local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(param.objectRef)]

                        if replacement then
                            param.objectRef = CreateNodeRef(replacement)
                        end
                    end

                    node.questNode.type.params = params
                elseif node.questNode.type:IsA("questPlayerLookAt_NodeType") then
                    local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(node.questNode.type.objectRef.reference)]

                    if replacement then
                        local objectRef = node.questNode.type.objectRef
                        objectRef.reference = CreateNodeRef(replacement)
                        node.questNode.type.objectRef = objectRef
                    end
                elseif node.questNode.type:IsA("questShowWorldNode_NodeType") then
                    local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(node.questNode.type.objectRef)]

                    if replacement then
                        node.questNode.type.objectRef = CreateNodeRef(replacement)
                    end
                end
            elseif node.questNode then
                if node.questNode:IsA("questEventManagerNodeDefinition") then
                    local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(node.questNode.objectRef.reference)]

                    if replacement then
                        local objectRef = node.questNode.objectRef
                        objectRef.reference = CreateNodeRef(replacement)
                        node.questNode.objectRef = objectRef
                    end
                elseif node.questNode.condition and node.questNode.condition.type and node.questNode.condition.type:IsA("questDevice_ConditionType") then
                    local replacement = helper.patches[path].propMap[utils.nodeRefToHashString(node.questNode.condition.type.objectRef)]

                    if replacement then
                        node.questNode.condition.type.objectRef = CreateNodeRef(replacement)
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