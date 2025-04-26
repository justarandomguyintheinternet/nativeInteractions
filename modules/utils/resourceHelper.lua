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

        local choiceIDs = {}
        for _, node in pairs(scene.sceneGraph.graph) do
            if node:IsA("scnChoiceNode") then
                table.insert(choiceIDs, node.nodeId.id)
                node.nodeId = scnNodeId.new({ id = node.nodeId.id + helper.patches[path].choiceID }) --node.nodeId.id + helper.patches[path].choiceID
            end
        end

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

        if helper.patches[path].animationPosition and helper.patches[path].animationRotation then
            for _, node in pairs(scene.sceneGraph.graph) do
                if node:IsA("scnSectionNode") then
                    for _, event in pairs(node.events) do
                        if event:IsA("scnPlaySkAnimEvent") then
                            local data = event.rootMotionData
                            data.originOffset = Transform.new({ position = ToVector4(helper.patches[path].animationPosition), orientation = ToEulerAngles(helper.patches[path].animationRotation):ToQuat() })
                            event.rootMotionData = data
                        end
                    end
                end
            end

            -- for _, workspot in pairs(scene.workspotInstances) do
            --     workspot.localTransform = Transform.new({ position = ToVector4(helper.patches[path].animationPosition), orientation = ToEulerAngles(helper.patches[path].animationRotation):ToQuat() })
            --     print(workspot.localTransform:GetPosition())
            -- end
        end

        -- print(scene.sceneGraph.graph[1].outputSockets[1].destinations[2].nodeId.id, "A")

        -- -- Copy
        -- local node = scene.sceneGraph.graph[1]
        -- local sockets = node.outputSockets
        -- local destinations = sockets[1].destinations

        -- destinations[2].nodeId = scnNodeId.new({ id = 1691 })

        -- -- Assign
        -- sockets[1].destinations = destinations
        -- node.outputSockets = sockets

        -- -- scene.sceneGraph.graph[3].nodeId = scnNodeId.new({ id = 1690 })
        -- print(scene.sceneGraph.graph[1].outputSockets[1].destinations[2].nodeId.id)--62
        -- print(scene.sceneGraph.graph[3].nodeId.id)--61


        -- for _, node in pairs(scene.sceneGraph.graph) do
        --     if node.nodeId.id == 1692 then
        --         print("NodeID", node.nodeId.id)
        --         node.nodeId = scnNodeId.new({ id = 1691 })
        --     end

        --     for _, socket in pairs(node.outputSockets) do
        --         for _, destination in pairs(socket.destinations) do
        --             if destination.nodeId.id == 1962 then
        --                 print("Destination", destination.nodeId.id)
        --                 destination.nodeId = scnNodeId.new({ id = 1691 })
        --             end
        --         end
        --     end
        -- end
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