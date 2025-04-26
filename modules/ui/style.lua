-- Most of the colors and style has been taken from https://github.com/psiberx/cp2077-red-hot-tools
local style = {
    mutedColor = 0xFFA5A19B,
    extraMutedColor = 0x96A5A19B,
    highlightColor = 0xFFDCD8D1,
    elementIndent = 35,
    draggedColor = 0xFF00007F,
    targetedColor = 0xFF00007F,
    regularColor = 0xFFFFFFFF
}

style.colors = { 0xFFF0F8FF, 0xFFFAEBD7, 0xFF00FFFF, 0xFF7FFFD4, 0xFFF0FFFF, 0xFFF5F5DC, 0xFFFFE4C4, 0xFFFFFFCD, 0xFF0000FF, 0xFF8A2BE2, 0xFFA52A2A, 0xFFDEB887, 0xFF5F9EA0, 0xFF7FFF00, 0xFFD2691E, 0xFFFF7F50, 0xFF6495ED, 0xFFFFF8DC, 0xFFDC143C, 0xFF00FFFF, 0xFF00008B, 0xFF008B8B, 0xFFB8860B, 0xFF006400, 0xFFBDB76B, 0xFF8B008B, 0xFF556B2F, 0xFFFF8C00, 0xFF9932CC, 0xFF8B0000, 0xFFE9967A, 0xFF8FBC8F, 0xFF483D8B, 0xFF00CED1, 0xFF9400D3, 0xFFFF1493, 0xFF00BFFF, 0xFF1E90FF, 0xFFB22222, 0xFFFFFAF0, 0xFF228B22, 0xFFFF00FF, 0xFFDCDCDC, 0xFFF8F8FF, 0xFFFFD700, 0xFFDAA520, 0xFF008000, 0xFFADFF2F, 0xFFF0FFF0, 0xFFFF69B4, 0xFFCD5C5C, 0xFF4B0082, 0xFFF0D58C, 0xFFE6E6FA, 0xFFFFF0F5, 0xFF7CFC00, 0xFFFFFACD, 0xFFADD8E6, 0xFFF08080, 0xFFE0FFFF, 0xFFFAFAD2, 0xFF90EE90, 0xFFD3D3D3, 0xFFFFB6C1, 0xFFFFA07A, 0xFF20B2AA, 0xFF778899, 0xFFB0C4DE, 0xFFFFFFE0, 0xFF00FF00, 0xFF32CD32, 0xFFFAF0E6, 0xFFFF00FF, 0xFF00000, 0xFF66CDAA, 0xFF0000CD, 0xFFBA55D3, 0xFF9370DB, 0xFF3CB371, 0xFF7B68EE, 0xFF00FA9A, 0xFF48D1CC, 0xFFC71385, 0xFF191970, 0xFFF5FFFA, 0xFFFFE4E1, 0xFFFFE4B5, 0xFFFFDEAD, 0xFF000080, 0xFFFDF5E6, 0xFF808000, 0xFF6B8E23, 0xFFFFA500, 0xFFFF4500, 0xFFDA70D6, 0xFFEEE8AA, 0xFF98FB98, 0xFFAFEEEE, 0xFFDB7093, 0xFFFFEFD5, 0xFFFFEFD5, 0xFFCD853F, 0xFFFFC0CB, 0xFFDDA0DD, 0xFFB0E0E6, 0xFF800080, 0xFF663399, 0xFFFF0000, 0xFFBC8F8F, 0xFF4169E1, 0xFF8B4513, 0xFFFA8072, 0xFFF4A460, 0xFF2E8B57, 0xFFFFF5EE, 0xFFA0522D, 0xFFC0C0C0, 0xFF87CEEB, 0xFF6A5ACD, 0xFFFFFAFA, 0xFF00FF7F, 0xFFD2B48C, 0xFF008080, 0xFFD8BFD8, 0xFFFF6347, 0xFF40E0D0, 0xFFEE82EE, 0xFFF5DEB3, 0xFFFFFFFF, 0xFFF5F5F5, 0xFFFFFF00, 0xFF9ACD32 }

local initialized = false

function style.initialize(force)
    if not force and initialized then return end
    style.viewSize = ImGui.GetFontSize() / 15
    initialized = true
end

function style.pushGreyedOut(state)
    if not state then return end

    ImGui.PushStyleColor(ImGuiCol.Button, 0xff777777)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff777777)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0xff777777)

    ImGui.PushStyleColor(ImGuiCol.FrameBg, 0xff777777)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0xff777777)
    ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0xff777777)
end

function style.popGreyedOut(state)
    if not state then return end

    ImGui.PopStyleColor(6)
end

function style.pushStyleColor(state, style, ...)
    if not state then return end

    ImGui.PushStyleColor(style, ...)
end

function style.pushStyleVar(state, style, ...)
    if not state then return end

    ImGui.PushStyleVar(style, ...)
end

---@param state boolean
---@param count number?
function style.popStyleVar(state, count)
    if not state then return end

    ImGui.PopStyleVar(count or 1)
end

---@param state boolean
---@param count number?
function style.popStyleColor(state, count)
    if not state then return end

    ImGui.PopStyleColor(count or 1)
end

function style.tooltip(text)
    if ImGui.IsItemHovered() then
        style.setCursorRelative(8, 8)

        ImGui.SetTooltip(text)
    end
end

function style.setCursorRelative(x, y)
    local xC, yC = ImGui.GetMousePos()
    ImGui.SetNextWindowPos(xC + x * style.viewSize, yC + y * style.viewSize, ImGuiCond.Always)
end

function style.setCursorRelativeAppearing(x, y)
    local xC, yC = ImGui.GetMousePos()
    ImGui.SetNextWindowPos(xC + x * style.viewSize, yC + y * style.viewSize, ImGuiCond.Appearing)
end

function style.lightToolTip(text)
    if ImGui.IsItemHovered() then
        local x, y = ImGui.GetMousePos()
        ImGui.SetNextWindowPos(x + 5 * style.viewSize, y + 5 * style.viewSize, ImGuiCond.Always)
        if ImGui.Begin("##tooltip", ImGuiWindowFlags.NoResize + ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoBackground) then
            style.mutedText(text)
            ImGui.End()
        end
    end
end

function style.spacedSeparator()
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()
end

---@param text string
---@param tooltip string?
function style.sectionHeaderStart(text, tooltip)
    ImGui.PushStyleColor(ImGuiCol.Text, style.mutedColor)
    ImGui.SetWindowFontScale(0.85)
    ImGui.Text(text)

    if tooltip then
        style.tooltip(tooltip)
    end

    ImGui.SetWindowFontScale(1)
    ImGui.PopStyleColor()
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.BeginGroup()
    ImGui.AlignTextToFramePadding()
end

function style.sectionHeaderEnd(noSpacing)
    ImGui.EndGroup()

    if not noSpacing then
        ImGui.Spacing()
        ImGui.Spacing()
    end
end

function style.mutedText(text)
    style.styledText(text, style.mutedColor)
end

---@param text string
---@param color number|table?
---@param size number?
function style.styledText(text, color, size)
    style.pushStyleColor(color ~= nil, ImGuiCol.Text, color)
    ImGui.SetWindowFontScale(size or 1)

    ImGui.Text(text)

    style.popStyleColor(color ~= nil)
    ImGui.SetWindowFontScale(1)
end

function style.pushButtonNoBG(push)
    if push then
        ImGui.PushStyleColor(ImGuiCol.Button, 0)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1, 1, 1, 0.2)
        ImGui.PushStyleVar(ImGuiStyleVar.ButtonTextAlign, 0.5, 0.5)
    else
        ImGui.PopStyleColor(2)
        ImGui.PopStyleVar()
    end
end

function style.toggleButton(text, state)
    style.pushStyleColor(not state, ImGuiCol.Text, style.mutedColor)
    style.pushButtonNoBG(true)
	ImGui.Button(text)
	style.popStyleColor(not state)
	style.pushButtonNoBG(false)
	if ImGui.IsItemClicked() then
		return not state, true
	end
    return state, false
end

function style.setNextItemWidth(width)
    ImGui.SetNextItemWidth(width * style.viewSize)
end

function style.getMaxWidth(min)
    local width = (ImGui.GetWindowContentRegionWidth() - ImGui.GetCursorPosX())
    width = math.max(width, min)

    return width / style.viewSize
end

function style.trackedSearchDropdown(text, searchHint, value, options, width)
    local finished = false

    ImGui.SetNextItemWidth(width * style.viewSize)
    if (ImGui.BeginCombo(text, value)) then
        local interiorWidth = width - (2 * ImGui.GetStyle().FramePadding.x) - 30
        value, _ = ImGui.InputTextWithHint("##search", searchHint, value, interiorWidth)
        local x, _ = ImGui.GetItemRectSize()

        ImGui.SameLine()
        style.pushButtonNoBG(true)
        if ImGui.Button(IconGlyphs.Close) then
            value = ""
        end
        style.pushButtonNoBG(false)

        local xButton, _ = ImGui.GetItemRectSize()
        if ImGui.BeginChild("##list", x + xButton + ImGui.GetStyle().ItemSpacing.x, 120 * style.viewSize) then
            for _, option in pairs(options) do
                if option:lower():match(value:lower()) and ImGui.Selectable(option) then
                    value = option
                    finished = true
                    ImGui.CloseCurrentPopup()
                end
            end

            ImGui.EndChild()
        end

        ImGui.EndCombo()
    end

    return value, finished
end

function style.buttonNoBG(text)
    style.pushButtonNoBG(true)
    if ImGui.Button(text) then
        style.pushButtonNoBG(false)
        return true
    end
    style.pushButtonNoBG(false)

    return false
end

function style.drawNoBGConditionalButton(condition, text, greyed)
    local push = false
    local greyed = greyed ~= nil and greyed or false

    if condition then
        ImGui.SameLine()
        style.pushButtonNoBG(true)
        style.pushGreyedOut(greyed)
        if ImGui.Button(text) then
            push = true
        end
        style.popGreyedOut(greyed)
        style.pushButtonNoBG(false)
    end

    return push
end

return style