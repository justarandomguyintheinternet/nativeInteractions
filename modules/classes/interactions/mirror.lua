local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")

---Class for mirror interaction
---@class mirror : workspot
---@field maxNodeRefPropertyWidth number?
---@field mirrorDeviceRef string?
---@field mirrorMeshRef string?
local mirror = setmetatable({}, { __index = workspot })

function mirror:new(mod, project)
    ---@class mirror
	local o = workspot.new(self, mod, project)

    o.interactionType = "Mirror"
    o.modulePath = "interactions/mirror"
    o.scene = "nif\\quest\\mirror.scene"
    o.skipFact = "nif_skip_mirror"
    o.endEvent = "nif_exit_mirror"
    o.startFactID = 11

    o.name = "Mirror Interaction"
    o.worldIcon = "ChoiceIcons.MirrorIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.MirrorRectangle

    o.maxNodeRefPropertyWidth = nil
    o.mirrorDeviceRef = ""
    o.mirrorMeshRef = ""

    setmetatable(o, { __index = self })
   	return o
end

function mirror:getPatchData()
    local data = workspot.getPatchData(self)

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_mirror_device")] = self.mirrorDeviceRef,
        [utils.nodeRefStringToHashString("$/nif_mirror_mesh")] = self.mirrorMeshRef
    }

    return data
end

function mirror:sessionStart()
    Game.GetWorldStateSystem():ToggleNode(CreateNodeRef(self.mirrorMeshRef), false)
end

function mirror:draw()
    workspot.draw(self)

    style.sectionHeaderStart("PROPS")

    if not self.maxNodeRefPropertyWidth then
        self.maxNodeRefPropertyWidth = utils.getTextMaxWidth({ "Mirror Device", "Mirror Mesh" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Mirror Device:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.mirrorDeviceRef, changed = ImGui.InputTextWithHint('##mirrorDeviceRef', '$/mod/#mirror_device', self.mirrorDeviceRef, 250)
    style.tooltip("Mirror device which handles the visual activation effect, and off state.")
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.mirrorDeviceRef, true)

    style.mutedText("Mirror Mesh:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxNodeRefPropertyWidth)
    style.setNextItemWidth(300)
    self.mirrorMeshRef, changed = ImGui.InputTextWithHint('##mirrorMeshRef', '$/mod/#mirror_mesh', self.mirrorMeshRef, 250)
    style.tooltip("Special mesh which renders the mirror reflection.")
    if changed then self.project:save() end
    ImGui.SameLine()
    style.drawNodeRefInfo(self.mirrorMeshRef, false)

    style.sectionHeaderEnd()
end

function mirror:save()
    local data = workspot.save(self)

    data.mirrorDeviceRef = self.mirrorDeviceRef
    data.mirrorMeshRef = self.mirrorMeshRef

    return data
end

return mirror