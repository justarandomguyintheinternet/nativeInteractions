local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for yakitori eating interaction
---@class yakitori : workspot
---@field maxNodeRefPropertyWidth number?
---@field stickRef string
---@field eatLevel number
---@field resetDistance number
local yakitori = setmetatable({}, { __index = workspot })

function yakitori:new(mod, project)
    ---@class yakitori
	local o = workspot.new(self, mod, project)

    o.interactionType = "Yakitori Eating"
    o.modulePath = "interactions/yakitori"
    o.scene = "nif\\quest\\yakitori.scene"
    o.skipFact = "nif_skip_yakitori"
    o.endEvent = "nif_exit_yakitori"
    o.startFactID = 19

    o.name = "Yakitori Eating Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.FoodDrumstickOutline

    o.maxNodeRefPropertyWidth = nil
    o.stickRef = ""
    o.resetDistance = 15
    o.eatLevel = 0

    setmetatable(o, { __index = self })
   	return o
end

function yakitori:load(data)
    workspot.load(self, data)

    CName.add("nif_eat_level")

    self:reset()
end

function yakitori:sessionStart()
    self:reset()
end

function yakitori:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_yakitori")] = self.stickRef
    }

    return data
end

function yakitori:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_eat_level", self.eatLevel)
    end

    workspot.start(self)
end

function yakitori:stop()
    if self.sceneRunning then
        self.eatLevel = Game.GetQuestsSystem():GetFactStr("nif_eat_level")
    end

    workspot.stop(self)
end

function yakitori:reset()
    self.eatLevel = 0
    if self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_eat_level", self.eatLevel)
    end

    local stick = utils.getEntityByRef(self.stickRef)

    if not stick then return end

    stick:FindComponentByName("full"):Toggle(true)
    stick:FindComponentByName("bite_1"):Toggle(false)
    stick:FindComponentByName("bite_2"):Toggle(false)
    stick:FindComponentByName("bite_3"):Toggle(false)
end

function yakitori:onUpdate(playerPosition)
    if self.sceneRunning then
        self.eatLevel = Game.GetQuestsSystem():GetFactStr("nif_eat_level")
    end

    if self.eatLevel == 0 then return end

    -- Reset stick if far away
    local distance = utils.vectorDistance(playerPosition, self.worldIconPosition)
    if distance > self.resetDistance and distance < self.resetDistance + 5 then
        self:reset()
    end
end

function yakitori:draw()
    workspot.draw(self)

    style.sectionHeaderStart("YAKITORI")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Yakitori Stick", "Reset Distance" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Yakitori Stick:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.stickRef, changed = ImGui.InputTextWithHint('##stickRef', '$/mod/#yakitori', self.stickRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.stickRef, true)

    style.mutedText("Reset Distance:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(80)
    self.resetDistance, changed = ImGui.DragFloat("##resetDistance", self.resetDistance, 0.01, 1, 50, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then self.project:save() end
    style.tooltip("Distance from the interaction icon where the yakitori stick will reset.")
    ImGui.SameLine()
    if ImGui.Button("Reset") then
        self:reset()
    end

    style.sectionHeaderEnd()
end

function yakitori:save()
    local data = workspot.save(self)

    data.stickRef = self.stickRef
    data.resetDistance = self.resetDistance

    return data
end

return yakitori