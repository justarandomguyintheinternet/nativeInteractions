local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for bar stool interaction
---@class bar : workspot
---@field maxNodeRefPropertyWidth number?
---@field maxActionPropertyWidth number?
---@field glassRef string
---@field enableDrink boolean
---@field enableSmoke boolean
---@field isDrinkWhiskey boolean
---@field isDrinkAlcohol boolean
---@field drinkLevel number
---@field resetDistance number
local bar = setmetatable({}, { __index = workspot })

function bar:new(mod, project)
    ---@class bar
	local o = workspot.new(self, mod, project)

    o.interactionType = "Bar Stool"
    o.modulePath = "interactions/bar"
    o.scene = "nif\\quest\\sit_drink_smoke.scene"
    o.skipFact = "nif_skip_bar"
    o.endEvent = "nif_exit_bar"
    o.startFactID = 7

    o.name = "Bar Stool Interaction"
    o.worldIcon = "ChoiceIcons.SitIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Liquor

    o.maxNodeRefPropertyWidth = nil
    o.maxActionPropertyWidth = nil
    o.glassRef = ""
    o.enableDrink = true
    o.enableSmoke = true
    o.isDrinkWhiskey = true
    o.isDrinkAlcohol = true
    o.resetDistance = 15

    o.drinkLevel = 0

    setmetatable(o, { __index = self })
   	return o
end

function bar:load(data)
    workspot.load(self, data)

    CName.add("nif_enable_drink")
    CName.add("nif_enable_smoke")
    CName.add("nif_drink_level")

    -- Will fill the glass if streamed in
    self:reset()
end

function bar:sessionStart()
    self:reset()
end

function bar:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_glass")] = self.glassRef
    }

    if not self.isDrinkWhiskey then
        data.locMap = {
            [6146] = CreateCRUID(1794109860333555716ULL)
        }
    end

    return data
end

function bar:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFact("nif_drink_level", self.drinkLevel)
        Game.GetQuestsSystem():SetFact("nif_enable_smoke", self.enableSmoke and 1 or 0)
        Game.GetQuestsSystem():SetFact("nif_drink_alcoholic", self.isDrinkAlcohol and 1 or 0)
    end

    workspot.start(self)
end

function bar:stop()
    if self.sceneRunning then
        self.drinkLevel = Game.GetQuestsSystem():GetFact("nif_drink_level")
    end

    workspot.stop(self)
end

function bar:reset()
    self.drinkLevel = 0
    if self.sceneRunning then
        Game.GetQuestsSystem():SetFact("nif_drink_level", self.drinkLevel)
    end

    local glass = utils.getEntityByRef(self.glassRef)

    if not glass then return end

    GameObjectEffectHelper.StartEffectEvent(glass, "d_liquid_whiskey_glass_full", true, worldEffectBlackboard.new())
end

function bar:onUpdate()
    if self.sceneRunning then
        self.drinkLevel = Game.GetQuestsSystem():GetFact("nif_drink_level")
        Game.GetQuestsSystem():SetFact("nif_enable_drink", (self.drinkLevel <= 2 and self.enableDrink) and 1 or 0)
        Game.GetQuestsSystem():SetFact("nif_enable_smoke", self.enableSmoke and 1 or 0)
    end

    if self.drinkLevel == 0 then return end

    -- Reset glass if far away
    local distance = GetPlayer():GetWorldPosition():Distance(ToVector4(self.worldIconPosition))
    if distance > self.resetDistance and distance < self.resetDistance + 5 then
        self:reset()
    end
end

function bar:draw()
    workspot.draw(self)

    style.sectionHeaderStart("ACTIONS")

    if not self.maxActionPropertyWidth then
        self.maxActionPropertyWidth = utils.getTextMaxWidth({ "Enable Whiskey Drinking", "Enable Smoking" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Enable Drinking:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxActionPropertyWidth)
    self.enableDrink, changed = ImGui.Checkbox('##enableDrink', self.enableDrink)
    if changed then self.project:save() end

    style.mutedText("Enable Smoking:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxActionPropertyWidth)
    self.enableSmoke, changed = ImGui.Checkbox('##enableSmoke', self.enableSmoke)
    if changed then self.project:save() end

    style.sectionHeaderEnd()

    if not self.enableDrink then
        return
    end

    style.sectionHeaderStart("DRINK")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Is Drink Whiskey", "Is Alcoholic", "Whiskey Glass", "Reset Distance" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Is Drink Whiskey:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    self.isDrinkWhiskey, changed = ImGui.Checkbox('##isDrinkWhiskey', self.isDrinkWhiskey)
    if changed then self.project:save() end
    style.tooltip("Determines the interaction text.")

    style.mutedText("Is Alcoholic:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    self.isDrinkAlcohol, changed = ImGui.Checkbox('##isDrinkAlcohol', self.isDrinkAlcohol)
    if changed then self.project:save() end
    style.tooltip("Determines if drinking applies the drunk effect.")

    style.mutedText("Whiskey Glass:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.glassRef, changed = ImGui.InputTextWithHint('##glassRef', '$/mod/#whiskey_glass', self.glassRef, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:reset()
    end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.glassRef, true)

    style.mutedText("Reset Distance:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(80)
    self.resetDistance, changed = ImGui.DragFloat("##resetDistance", self.resetDistance, 0.01, 1, 50, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
    if changed then self.project:save() end
    style.tooltip("Distance from the interaction icon where the drink level will reset.")
    ImGui.SameLine()
    if ImGui.Button("Reset") then
        self:reset()
    end

    style.sectionHeaderEnd()
end

function bar:save()
    local data = workspot.save(self)

    data.glassRef = self.glassRef
    data.enableDrink = self.enableDrink
    data.enableSmoke = self.enableSmoke
    data.resetDistance = self.resetDistance
    data.isDrinkWhiskey = self.isDrinkWhiskey
    data.isDrinkAlcohol = self.isDrinkAlcohol

    return data
end

return bar