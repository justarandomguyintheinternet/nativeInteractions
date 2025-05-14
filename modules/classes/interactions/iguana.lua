local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local workspot = require("modules/classes/interactions/workspot")

---Class for iguana interaction
---@class iguana : workspot
---@field maxNodeRefPropertyWidth number?
---@field iguanaRef string
---@field animationDistance number
local iguana = setmetatable({}, { __index = workspot })

function iguana:new(mod, project)
    ---@class iguana
	local o = workspot.new(self, mod, project)

    o.interactionType = "Iguana"
    o.modulePath = "interactions/iguana"
    o.scene = "nif\\quest\\iguana.scene"
    o.skipFact = "nif_skip_iguana"
    o.endEvent = "nif_exit_iguana"
    o.startFactID = 18

    o.name = "Iguana Interaction"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Tortoise

    o.maxNodeRefPropertyWidth = nil
    o.iguanaRef = ""
    o.animationDistance = 35

    o.animationActive = false
    o.choiceActive = false

    setmetatable(o, { __index = self })
   	return o
end

function iguana:load(data)
    workspot.load(self, data)

    CName.add("nif_iguana_choice")
end

function iguana:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_iguana")] = self.iguanaRef
    }

    return data
end

function iguana:start()
    if resourceHelper.endEvents[self.endEvent] and not self.animationActive then return end

    Game.GetQuestsSystem():SetFact("nif_iguana_choice", 1)
end

function iguana:stop()
    if not self.sceneRunning or (resourceHelper.endEvents[self.endEvent] and not self.animationActive) then return end

    Game.GetQuestsSystem():SetFact("nif_iguana_choice", 0)
end

function iguana:onUpdate()
    local distance = GetPlayer():GetWorldPosition():Distance(ToVector4(self.worldIconPosition))
    if distance < self.animationDistance and not self.animationActive and not resourceHelper.endEvents[self.endEvent] then
        workspot.start(self)
        self.animationActive = true
    elseif distance > self.animationDistance and self.animationActive then
        workspot.stop(self)
        self.animationActive = false
    end
end

function iguana:draw()
    workspot.draw(self)

    style.sectionHeaderStart("IGUANA")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Iguana" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Try to limit this interaction to at most one per location.")
    style.mutedText(string.format("Distance between two iguanas should be at least %dm.", self.animationDistance * 2))

    style.mutedText("Iguana:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.iguanaRef, changed = ImGui.InputTextWithHint('##iguanaRef', '$/mod/#iguana', self.iguanaRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.iguanaRef, false)

    style.sectionHeaderEnd()
end

function iguana:save()
    local data = workspot.save(self)

    data.iguanaRef = self.iguanaRef

    return data
end

return iguana