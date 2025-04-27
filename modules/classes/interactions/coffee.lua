local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for coffee interaction
---@class coffee : workspot
---@field maxNodeRefPropertyWidth number?
---@field coffeeMugRef string?
---@field coffeeMachineRef string?
local coffee = setmetatable({}, { __index = workspot })

function coffee:new(mod, project)
    ---@class coffee
	local o = workspot.new(self, mod, project)

    o.interactionType = "Coffee"
    o.modulePath = "interactions/coffee"
    o.scene = "quest\\coffee.scene"
    o.skipFact = "nif_skip_coffee"
    o.endEvent = "nif_exit_coffee"
    o.startFactID = 6

    o.name = "Coffee Interaction"
    o.worldIcon = "ChoiceIcons.DrinkIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.CoffeeMakerOutline

    o.maxNodeRefPropertyWidth = nil
    o.coffeeMugRef = ""
    o.coffeeMachineRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function coffee:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_coffeemug")] = self.coffeeMugRef,
        [utils.nodeRefStringToHashString("$/nif_coffeemachine")] = self.coffeeMachineRef
    }

    return data
end

function coffee:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Coffee Mug", "Coffee Machine" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Coffe Mug:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.coffeeMugRef, changed = ImGui.InputTextWithHint('##coffeeMugRef', '$/mod/#coffee_mug', self.coffeeMugRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.coffeeMugRef)

    style.mutedText("Coffe Machine:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.coffeeMachineRef, changed = ImGui.InputTextWithHint('##coffeeMachineRef', '$/mod/#coffee_machine', self.coffeeMachineRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.coffeeMachineRef)

    style.sectionHeaderEnd()
end

function coffee:save()
    local data = workspot.save(self)

    data.coffeeMugRef = self.coffeeMugRef
    data.coffeeMachineRef = self.coffeeMachineRef

    return data
end

return coffee