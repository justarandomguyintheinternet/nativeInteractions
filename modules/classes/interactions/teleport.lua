local style = require("modules/ui/style")
local interaction = require("modules/classes/interaction")
local utils = require("modules/utils/utils")

---Class for teleport interaction
---@class teleport : interaction
---@field targetRef string
---@field locStringIDOverride string
local teleport = setmetatable({}, { __index = interaction })

function teleport:new(mod, project)
    ---@class interaction
	local o = interaction.new(self, mod, project)

    o.interactionType = "Teleport"
    o.modulePath = "interactions/teleport"
    o.scene = "nif\\quest\\teleport.scene"
    o.skipFact = "nif_skip_teleport"
    o.endEvent = "nif_exit_teleport"
    o.startFactID = 24

    o.name = "Default Interaction"
    o.worldIcon = "ChoiceIcons.FastTravelIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.AccountArrowRightOutline

    o.targetRef = ""
    o.locStringIDOverride = ""

    setmetatable(o, { __index = self })
   	return o
end

function teleport:getPatchData()
    local data = interaction.getPatchData(self)

    data.propMap = {
        ["8881591269491424326"] = self.targetRef
    }

    if self.locStringIDOverride ~= "" then
        data.locMap = {
            [6146] = CreateCRUID(loadstring("return " .. self.locStringIDOverride .. "ULL", "")())
        }
    end

    return data
end

function teleport:draw()
    interaction.draw(self)

    style.sectionHeaderStart("OPTIONS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Destination NodeRef", "LocStringID Override" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Destination:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.targetRef, changed = ImGui.InputTextWithHint('##targetRef', '$/mod/#target', self.targetRef, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.tooltip("NodeRef of a node who will be used as the destination of the teleport.\nThe node MUST be already streamed in when at the teleport interaction.")
    style.drawNodeRefInfo(self.targetRef, false)

    style.mutedText("LocStringID Override:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.locStringIDOverride, changed = ImGui.InputTextWithHint('##locStringIDOverride', '', self.locStringIDOverride, 250)
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawHelp("Override LocStringID for the interaction prompt. Is NOT a LocKey, use SoundDB to find a fitting replacement.", "https://sounddb.redmodding.org/subtitles")

    style.sectionHeaderEnd()
end

function teleport:save()
    local data = interaction.save(self)

    data.targetRef = self.targetRef
    data.locStringIDOverride = self.locStringIDOverride

    return data
end

return teleport