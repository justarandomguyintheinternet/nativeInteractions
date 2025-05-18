local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local resourceHelper = require("modules/utils/resourceHelper")
local workspot = require("modules/classes/interactions/workspot")
local Cron = require("modules/utils/Cron")

---Class for iguana interaction
---@class iguana : workspot
---@field maxNodeRefPropertyWidth number?
---@field iguanaRef string
---@field animationDistance number
---@field animationActive boolean
---@field startCron number?
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
    o.startCron = nil

    setmetatable(o, { __index = self })
   	return o
end

function iguana:load(data)
    workspot.load(self, data)

    CName.add("nif_iguana_idle")
end

function iguana:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_iguana")] = self.iguanaRef
    }

    return data
end

function iguana:sessionStart()
    self.animationActive = false
end

function iguana:onUpdate()
    local distance = GetPlayer():GetWorldPosition():Distance(ToVector4(self.worldIconPosition))

    if utils.getEntityByRef(self.iguanaRef) and distance < self.animationDistance - 1 and not self.animationActive and not resourceHelper.endEvents[self.endEvent] and Game.GetQuestsSystem():GetFact("nif_iguana_idle") == 0 then
        -- Delay needed for session start
        self.startCron = Cron.After(0.1, function ()
            Game.GetResourceDepot():RemoveResourceFromCache("nif\\quest\\iguana_idle.scene")
            resourceHelper.registerPatch("nif\\quest\\iguana_idle.scene", self:getPatchData())
            Game.GetQuestsSystem():SetFact("nif_interaction_id", 21)
            Game.GetQuestsSystem():SetFact("nif_start_signal", 1)
        end)

        self.animationActive = true
    elseif distance > self.animationDistance + 1 and self.animationActive then
        Game.GetQuestsSystem():SetFact("nif_iguana_idle", 0)
        self.animationActive = false

        if self.startCron then
            Cron.Halt(self.startCron)
            self.startCron = nil
        end
    end
end

function iguana:draw()
    workspot.draw(self, "after getting at least " .. self.animationDistance .. "m from the interaction.")

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
    style.drawNodeRefInfo(self.iguanaRef, true)

    style.sectionHeaderEnd()
end

function iguana:save()
    local data = workspot.save(self)

    data.iguanaRef = self.iguanaRef

    return data
end

return iguana