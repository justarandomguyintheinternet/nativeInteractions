local style = require("modules/ui/style")
local utils = require("modules/utils/utils")
local workspot = require("modules/classes/interactions/workspot")
local apartmentManager = require("modules/apartmentManager")
local world = require("modules/utils/worldInteraction")
local Cron = require("modules/utils/Cron")

---Class for apartment purchase interaction
---@class apartment : workspot
---@field maxBasePropertyWidth number?
---@field maxTerminalPropertyWidth number?
---@field maxMappinPropertyWidth number?
---@field maxOptionalPropertyWidth number?
---@field maxTutorialPropertyWidth number?
---@field isTablet boolean
---@field tabletRef string
---@field terminalRef string
---@field apartmentName string
---@field apartmentPurchasePosition { x: number, y: number, z: number }
---@field apartmentPurchasedPosition { x: number, y: number, z: number }
---@field apartmentEntrancePosition { x: number, y: number, z: number }
---@field useCustomKey boolean
---@field apartmentKeyTDBID string
---@field purchasedFact string
---@field enablePurchaseFact string
---@field cost number
---@field apartmentPictureAtlas string
---@field apartmentPicturePart string
---@field useIconRecord boolean
---@field apartmentPictureRecord string
---@field apartmentVideo string
---@field messageLocKey string
---@field tutorialLocKey string
---@field tutorialEnabled boolean
---@field purchaseMappinID userdata
---@field apartmentMappinID userdata
---@field messageDelayCron number
local apartment = setmetatable({}, { __index = workspot })

function apartment:new(mod, project)
    ---@class apartment
	local o = workspot.new(self, mod, project)

    o.interactionType = "Apartment Purchase"
    o.modulePath = "interactions/apartment"
    o.scene = "nif\\quest\\apartment.scene"
    o.skipFact = "nif_skip_apartment"
    o.endEvent = "nif_exit_apartment"
    o.startFactID = 22

    o.name = "Apartment Purchase Interaction"
    o.worldIcon = "ChoiceIcons.PayIcon"
    o.worldIconRange = 5
    o.interactionAngle = 80
    o.interactionRange = 1.5
    o.editorIcon = IconGlyphs.Home

    o.maxBasePropertyWidth = nil
    o.maxTerminalPropertyWidth = nil
    o.maxMappinPropertyWidth = nil
    o.maxOptionalPropertyWidth = nil
    o.maxTutorialPropertyWidth = nil

    o.isTablet = false
    o.tabletRef = ""
    o.terminalRef = ""

    o.apartmentName = ""
    o.apartmentPurchasePosition = { x = 0, y = 0, z = 0 }
    o.apartmentPurchasedPosition = { x = 0, y = 0, z = 0 }
    o.apartmentEntrancePosition = { x = 0, y = 0, z = 0 }
    o.useCustomKey = false
    o.apartmentKeyTDBID = ""

    o.purchasedFact = ""
    o.enablePurchaseFact = ""
    o.cost = 30000

    o.apartmentPictureAtlas = ""
    o.apartmentPicturePart = ""
    o.useIconRecord = false
    o.apartmentPictureRecord = ""
    o.messageLocKey = ""

    o.tutorialEnabled = false
    o.apartmentVideo = ""
    o.tutorialLocKey = ""

    o.purchaseMappinID = nil
    o.apartmentMappinID = nil
    o.messageDelayCron = nil

    setmetatable(o, { __index = self })
   	return o
end

local function reloadJournalOnEdit()
    if ImGui.IsItemDeactivatedAfterEdit() then
        Game.GetResourceDepot():RemoveResourceFromCache("nif\\dummy.journal")
        ArchiveXL.Reload()
    end
end

function apartment:load(data)
    workspot.load(self, data)

    apartmentManager.addApartment(self)

    CName.add(self.purchasedFact)
    CName.add(self.purchasedFact .. "_tutorial")
    CName.add(self.enablePurchaseFact)
    self:addKey()
    self:addIcon()
    self:addOffer()
end

function apartment:remove()
    workspot.remove(self)

    self:removeKey()
    self:removeIcon()
    self:removeOffer()
    self:sessionEnd()

    apartmentManager.removeApartment(self)
end

function apartment:getPatchData()
    local data = workspot.getPatchData(self)

    data.tdbidMap = {
        ["EconomicAssignment.vs_apartment_dlc6_apart_wat_nid"] = "EconomicAssignment." .. self.purchasedFact
    }

    data.propMap = {
        [utils.nodeRefStringToHashString("$/nif_terminal")] = self.terminalRef,
        [utils.nodeRefStringToHashString("$/nif_tablet")] = self.tabletRef
    }

    return data
end

function apartment:getJournalPatch()
    return {
        getID = function ()
            return self.purchasedFact
        end,
        patches = {
            ["contacts/muamar_el_capitan_reyes/apartments"] = {
                getEntry = function ()
                    local message = gameJournalPhoneMessage.new()
                    message.id = self.purchasedFact
                    message.text = ToLocalizationString(self.messageLocKey)
                    message.imageId = self:getIconTDBID()
                    return message
                end
            }
        }
    }
end

function apartment:start()
    if not self.sceneRunning then
        Game.GetQuestsSystem():SetFactStr("nif_apartment_type", self.isTablet and 0 or 1)
    end

    workspot.start(self)
end

function apartment:sessionStart()
    -- Remove any mappins
    self:sessionEnd()

    -- Add purchased mappin and disable interaction if already purchased
    if Game.GetQuestsSystem():GetFactStr(self.purchasedFact) == 1 then
        local data = MappinData.new({ mappinType = "Mappins.FastTravelStaticMappin", variant = gamedataMappinVariant.ApartmentVariant})
        self.apartmentMappinID = Game.GetMappinSystem():RegisterMappin(data, ToVector4(self.apartmentPurchasedPosition))

        world.disableInteraction(self.worldInteractionID, true)

        return
    end

    if not self:purchaseEnabled() then
        world.disableInteraction(self.worldInteractionID, true)
        return
    end

    -- Enable interaction and add purchasing mappin
    local data = MappinData.new({ mappinType = "Mappins.FastTravelStaticMappin", variant = gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant})
    self.purchaseMappinID = Game.GetMappinSystem():RegisterMappin(data, ToVector4(self.apartmentPurchasePosition))
    world.disableInteraction(self.worldInteractionID, false)
end

function apartment:reset()
    Game.GetQuestsSystem():SetFactStr(self.purchasedFact, 0)
    Game.GetQuestsSystem():SetFactStr(self.purchasedFact .. "_tutorial", 0)

    local data = Game.GetTransactionSystem():GetItemData(GetPlayer(), ItemID.FromTDBID(self:getKeyTDBID()))
    if data then
        data:RemoveDynamicTag("Quest")
    end
    Game.GetTransactionSystem():RemoveItem(GetPlayer(), ItemID.FromTDBID(self:getKeyTDBID()), 9999)

    Game.AddToInventory("Items.money", self.cost)
    Game.GetJournalManager():ChangeEntryState('contacts/muamar_el_capitan_reyes/apartments/' .. self.purchasedFact, 'gameJournalPhoneMessage', gameJournalEntryState.Inactive, gameJournalNotifyOption.Notify)

    self:sessionStart()
end

function apartment:sessionEnd()
    if self.purchaseMappinID then
        Game.GetMappinSystem():UnregisterMappin(self.purchaseMappinID)
        self.purchaseMappinID = nil
    end

    if self.apartmentMappinID then
        Game.GetMappinSystem():UnregisterMappin(self.apartmentMappinID)
        self.apartmentMappinID = nil
    end

    if self.messageDelayCron then
        Cron.Halt(self.messageDelayCron)
        self.messageDelayCron = nil
    end
end

function apartment:onSceneEnd()
    workspot.onSceneEnd(self)

    if Game.GetQuestsSystem():GetFactStr("nif_purchased_signal") == 1 then
        Game.GetQuestsSystem():SetFactStr("nif_purchased_signal", 0)
        Game.GetQuestsSystem():SetFactStr(self.purchasedFact, 1)

        if self.purchaseMappinID then
            Game.GetMappinSystem():UnregisterMappin(self.purchaseMappinID)
            self.purchaseMappinID = nil
        end

        if not Game.GetTransactionSystem():HasItem(GetPlayer(), ItemID.FromTDBID(self:getKeyTDBID())) then
            Game.GetTransactionSystem():GiveItem(GetPlayer(), ItemID.FromTDBID(self:getKeyTDBID()), 1, { "Quest" })
        end

        Game.GetTransactionSystem():RemoveItem(GetPlayer(), ItemID.FromTDBID("Items.money"), self.cost)

        self:sessionStart()
    end
end

function apartment:canSendMessage(canPurchase)
    local journalManager = Game.GetJournalManager()

    local inactive = journalManager:GetEntryState(journalManager:GetEntryByString('contacts/muamar_el_capitan_reyes/apartments/' .. self.purchasedFact, 'gameJournalPhoneMessage')) == gameJournalEntryState.Inactive
    if not inactive then return false end
    local contactEnabled = journalManager:GetEntryState(journalManager:GetEntryByString('contacts/muamar_el_capitan_reyes/apartments', 'gameJournalPhoneConversation')) == gameJournalEntryState.Active
    if not contactEnabled then return false end
    local canPurchase = canPurchase == nil and self:purchaseEnabled() or canPurchase

    return canPurchase and self.messageLocKey ~= "" and self.messageDelayCron == nil
end

function apartment:sendMessage()
    if self.purchasedFact == "" then return end

    self.messageDelayCron = Cron.After(2.5, function ()
        Game.GetJournalManager():ChangeEntryState('contacts/muamar_el_capitan_reyes/apartments/' .. self.purchasedFact, 'gameJournalPhoneMessage', gameJournalEntryState.Inactive, gameJournalNotifyOption.Notify)
        Game.GetJournalManager():ChangeEntryState('contacts/muamar_el_capitan_reyes/apartments/' .. self.purchasedFact, 'gameJournalPhoneMessage', gameJournalEntryState.Active, gameJournalNotifyOption.Notify)

        self.messageDelayCron = nil
    end)
end

function apartment:onUpdate(playerPosition)
    local purchaseEnabled = self:purchaseEnabled()

    -- Handle purchasing mappin becoming available
    if purchaseEnabled and not self.purchaseMappinID then
        self:sessionStart()
    elseif not purchaseEnabled and self.purchaseMappinID then
        self:sessionStart()
    end

    if purchaseEnabled and self.messageLocKey ~= "" and self:canSendMessage(purchaseEnabled) then
        self:sendMessage()
    end

    -- Show tutorial
    if not self.tutorialEnabled or Game.GetQuestsSystem():GetFactStr(self.purchasedFact) == 0 or Game.GetQuestsSystem():GetFactStr(self.purchasedFact .. "_tutorial") == 1 then return end

    if utils.vectorDistance(playerPosition, self.apartmentEntrancePosition) < 1.2 then
        Game.GetQuestsSystem():SetFactStr(self.purchasedFact .. "_tutorial", 1)
        utils.showTutorial(self.tutorialLocKey, self.apartmentName, self.apartmentVideo)
    end
end

function apartment:addKey()
    if self.purchasedFact == "" then return end

    TweakDB:CloneRecord("Keycards." .. self.purchasedFact, "Keycards.dlc6_apart_cct_dtn_keycard")
    TweakDB:SetFlat("Keycards." .. self.purchasedFact .. ".localizedDescription", utils.getPrimaryKey("LocKey#95093"))
    TweakDB:SetFlat("Keycards." .. self.purchasedFact .. ".displayName", utils.getPrimaryKey(self.apartmentName))
end

function apartment:removeKey()
    TweakDB:DeleteRecord("Keycards." .. self.purchasedFact)
end

function apartment:removeIcon()
    TweakDB:DeleteRecord("UIJournalIcons." .. self.purchasedFact)
end

function apartment:removeOffer()
    TweakDB:DeleteRecord("EconomicAssignment." .. self.purchasedFact)
    TweakDB:DeleteRecord("Apartment." .. self.purchasedFact)
end

function apartment:addIcon()
    if self.purchasedFact == "" then return end

    TweakDB:CloneRecord("UIJournalIcons." .. self.purchasedFact, "UIJournalIcons.ExampleIcon")
    TweakDB:SetFlat("UIJournalIcons." .. self.purchasedFact .. ".atlasPartName", self.apartmentPicturePart)
    TweakDB:SetFlat("UIJournalIcons." .. self.purchasedFact .. ".atlasResourcePath", self.apartmentPictureAtlas)
end

function apartment:addOffer()
    if self.purchasedFact == "" then return end

    TweakDB:CloneRecord("EconomicAssignment." .. self.purchasedFact, "EconomicAssignment.vs_apartment_dlc6_apart_cct_dtn")
    TweakDB:SetFlat("EconomicAssignment." .. self.purchasedFact .. ".overrideValue", self.cost)

    TweakDB:CloneRecord("Apartment." .. self.purchasedFact, "Apartment.japantown_offer")
    TweakDB:SetFlat("Apartment." .. self.purchasedFact .. ".name", utils.getPrimaryKey(self.apartmentName))
    TweakDB:SetFlat("Apartment." .. self.purchasedFact .. ".previewImage", self:getIconTDBID())
    TweakDB:SetFlat("Apartment." .. self.purchasedFact .. ".price", "EconomicAssignment." .. self.purchasedFact)
end

function apartment:getKeyTDBID()
    if self.useCustomKey then
        return self.apartmentKeyTDBID
    end

    return self.purchasedFact ~= "" and "Keycards." .. self.purchasedFact or ""
end

function apartment:getIconTDBID()
    if self.useIconRecord then
        return self.apartmentPictureRecord ~= "" and self.apartmentPictureRecord or "UIJournalIcons.Q114_blueprint"
    end

    return self.purchasedFact ~= "" and "UIJournalIcons." .. self.purchasedFact or "UIJournalIcons.Q114_blueprint"
end

function apartment:purchaseEnabled()
    local purchased = Game.GetQuestsSystem():GetFactStr(self.purchasedFact) == 1

    if self.enablePurchaseFact ~= "" then
        return Game.GetQuestsSystem():GetFactStr(self.enablePurchaseFact) == 1 and not purchased
    end

    return not purchased
end

function apartment:drawBase()
    style.sectionHeaderStart("BASE")

    if not self.maxBasePropertyWidth then
        self.maxBasePropertyWidth = utils.getTextMaxWidth({ "Apartment Name", "Purchased Fact", "Cost", "Key TweakDBID", "Enable Purchase Fact" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Purchased Fact:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    style.setNextItemWidth(250)
    local text, changed = ImGui.InputTextWithHint('##purchasedFact', 'apartment_id', self.purchasedFact, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() then
        self:removeKey()
        self:removeIcon()
        self:removeOffer()
        CName.add(text)
        CName.add(text .. "_tutorial")
        self.purchasedFact = text
        self:addKey()
        self:addIcon()
        self:addOffer()
        -- Update mappins
        self:sessionStart()
    end
    reloadJournalOnEdit()
    style.tooltip("Must be set to something. This fact will be set to 1 when the apartment is purchased.")

    style.mutedText("Apartment Name:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    style.setNextItemWidth(250)
    self.apartmentName, changed = ImGui.InputTextWithHint('##apartmentName', 'LocKey#123', self.apartmentName, 250)
    if changed then self.project:save() end
    if ImGui.IsItemDeactivatedAfterEdit() and self:getKeyTDBID() ~= "" then
        self:removeKey()
        self:removeOffer()
        self:addKey()
        self:addOffer()
        self.project:save()
    end
    ImGui.SameLine()
    style.drawHelp("Existing LocKey's can be found in WolvenKit, and new ones can be added using ArchiveXL", "https://wiki.redmodding.org/cyberpunk-2077-modding/modding-guides/vehicles/boe6s-guide-new-car-from-a-to-z/create-base-files#create-a-.json-file")

    style.mutedText("Cost:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    style.setNextItemWidth(100)
    self.cost, changed = ImGui.InputInt('##cost', self.cost, 1, 1000000)
    if changed then
        self.project:save()
        self:removeOffer()
        self:addOffer()
    end

    style.mutedText("Use Custom Key:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    self.useCustomKey, changed = ImGui.Checkbox("##useCustomKey", self.useCustomKey)
    if changed then
        self.project:save()
        if not self.useCustomKey then
            self:addKey()
        else
            self:removeKey()
        end
    end
    style.tooltip("If enabled, the apartment will use a custom key item.\nTweakDB record must be created manually in that case.")

    style.mutedText("Key TweakDBID:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    if self.useCustomKey then
        style.setNextItemWidth(250)
        self.apartmentKeyTDBID, changed = ImGui.InputTextWithHint('##apartmentKeyTDBID', 'Keycards.apartment_key', self.apartmentKeyTDBID, 250)
        if changed then self.project:save() end
    else
        ImGui.Text("Keycards." .. (self.purchasedFact ~= "" and self.purchasedFact or "MISSING"))

        if self.purchasedFact ~= "" then ImGui.SameLine() end
        if self.purchasedFact ~= "" and style.buttonNoBG(IconGlyphs.ContentCopy) then
            ImGui.SetClipboardText("Keycards." .. self.purchasedFact)
            ImGui.ShowToast(ImGui.Toast.new(ImGui.ToastType.Success, 2500, string.format("Copied to clipboard: Keycards.%s", self.purchasedFact)))
        end
    end
    style.tooltip("TweakDBID of the key that will be given to the player when they purchase the apartment.")

    style.mutedText("Enable Purchase Fact:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxBasePropertyWidth)
    style.setNextItemWidth(250)
    self.enablePurchaseFact, changed = ImGui.InputTextWithHint('##enablePurchaseFact', 'apartment_purchase_enabled', self.enablePurchaseFact, 250)
    if changed then self.project:save() end
    style.tooltip("Optional fact that controls whether the purchase interaction and mappin is enabled.")

    style.sectionHeaderEnd(true)
end

function apartment:drawPurchaseTerminal()
    style.sectionHeaderStart("PURCHASE TERMINAL")

    if not self.maxTerminalPropertyWidth then
        self.maxTerminalPropertyWidth = utils.getTextMaxWidth({ "Purchase Object", "Purchase Object NodeRef" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Purchase Object:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxTerminalPropertyWidth)
    style.setNextItemWidth(150)
    local value, changed = ImGui.Combo("##objectType", self.isTablet and 1 or 0, {"Door Terminal", "Tablet Hand Scanner"}, 2)
    if changed then
        self.isTablet = value == 1
        self.project:save()
        if self.isTablet then
            self:editStart()
        else
            self:editEnd()
        end
    end
    style.tooltip("Type of the purchase terminal that will be used for this apartment.\nTablet Hand Scanner includes a workspot / animation, while Door Terminal is a simple interaction.")

    style.mutedText("Purchase Object NodeRef:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxTerminalPropertyWidth)
    style.setNextItemWidth(250)
    local ref, changed = ImGui.InputTextWithHint('##terminalRef', '$/mod/#apartment_terminal', self.isTablet and self.tabletRef or self.terminalRef, 250)
    if changed then
        self.project:save()

        if self.isTablet then
            self.tabletRef = ref
        else
            self.terminalRef = ref
        end
    end
    style.tooltip("NodeRef of the purchase terminal/scanner that will be used for this apartment.")
    ImGui.SameLine()
    style.drawNodeRefInfo(self.isTablet and self.tabletRef or self.terminalRef, true)

    style.sectionHeaderEnd(true)
end

function apartment:drawPositions()
    style.sectionHeaderStart("POSITIONS")

    if not self.maxMappinPropertyWidth then
        self.maxMappinPropertyWidth = utils.getTextMaxWidth({ "Purchase Mappin Position", "Purchased Mappin Position" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Purchase Mappin Position:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxMappinPropertyWidth)
    self.apartmentPurchasePosition, _, finished = self.mod.baseUI.interactionUI.drawPosition(self.apartmentPurchasePosition, "purchase")
    if finished then
        self.project:save()
        if self.purchaseMappinID then
            Game.GetMappinSystem():SetMappinPosition(self.purchaseMappinID, ToVector4(self.apartmentPurchasePosition))
        elseif not self.purchaseMappinID then
            self:sessionStart()
        end
    end
    ImGui.SameLine()
    style.mutedText(IconGlyphs.HelpCircleOutline)
    style.tooltip("Position where the \"Purchase\"-type mappin will be placed, should be on the purchase terminal/scanner")

    style.mutedText("Purchased Mappin Position:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxMappinPropertyWidth)
    self.apartmentPurchasedPosition, _, finished = self.mod.baseUI.interactionUI.drawPosition(self.apartmentPurchasedPosition, "purchased")
    if finished then
        self.project:save()
        if self.apartmentMappinID then
            Game.GetMappinSystem():SetMappinPosition(self.apartmentMappinID, ToVector4(self.apartmentPurchasedPosition))
        elseif not self.apartmentMappinID then
            self:sessionStart()
        end
    end
    ImGui.SameLine()
    style.mutedText(IconGlyphs.HelpCircleOutline)
    style.tooltip("Position where the apartment mappin will be placed once purchased.")

    style.sectionHeaderEnd(true)
end

function apartment:drawMedia()
    style.sectionHeaderStart("MEDIA")

    if not self.maxOptionalPropertyWidth then
        self.maxOptionalPropertyWidth = utils.getTextMaxWidth({ "Picture Atlas Path", "Atlas Part", "Video Path", "Purchase Message" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Use Icon Record:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxOptionalPropertyWidth)
    self.useIconRecord, changed = ImGui.Checkbox("##useIconRecord", self.useIconRecord)
    if changed then
        self.project:save()
        if not self.useIconRecord then
            self:addIcon()
        else
            self:removeIcon()
        end
    end
    reloadJournalOnEdit()
    style.tooltip("If enabled, the apartment picture will be set using a TweakDB record.\nIf disabled, the atlas and part will be used instead.")

    if not self.useIconRecord then
        style.mutedText("Picture Atlas Path:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxOptionalPropertyWidth)
        style.setNextItemWidth(250)
        self.apartmentPictureAtlas, changed = ImGui.InputTextWithHint('##apartmentPictureAtlas', 'base\\apartment\\images.inkatlas', self.apartmentPictureAtlas, 250)
        if changed then
            self.project:save()
            self:removeIcon()
            self:addIcon()
        end
        reloadJournalOnEdit()
        style.tooltip("Path to the atlas that contains the apartment picture.")

        style.mutedText("Atlas Part:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxOptionalPropertyWidth)
        style.setNextItemWidth(150)
        self.apartmentPicturePart, changed = ImGui.InputTextWithHint('##apartmentPicturePart', 'part_name', self.apartmentPicturePart, 50)
        if changed then
            self.project:save()
            self:removeIcon()
            self:addIcon()
        end
        reloadJournalOnEdit()
        style.tooltip("Name of the atlas part that contains the apartment picture.")
    else
        style.mutedText("Picture Record:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxOptionalPropertyWidth)
        style.setNextItemWidth(250)
        self.apartmentPictureRecord, changed = ImGui.InputTextWithHint('##apartmentPictureRecord', 'UIJournalIcons.l_costview', self.apartmentPictureRecord, 250)
        if changed then self.project:save() end
        reloadJournalOnEdit()
        style.tooltip("TweakDBID of the icon record that will be used for the apartment picture.")
    end

    style.mutedText("Purchase Message:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxOptionalPropertyWidth)
    style.setNextItemWidth(250)
    local newText, _ = ImGui.InputTextWithHint('##messageLocKey', 'LocKey#99999', self.messageLocKey, 250)
    if ImGui.IsItemDeactivatedAfterEdit() then
        self.messageLocKey = newText
        self.project:save()
    end
    reloadJournalOnEdit()
    style.tooltip("Optional LocKey for a message that will be sent by El Capitan when the apartment can be purchased.")
    ImGui.SameLine()
    if style.buttonNoBG(IconGlyphs.Reload) then
        Game.GetJournalManager():ChangeEntryState('contacts/muamar_el_capitan_reyes/apartments/' .. self.purchasedFact, 'gameJournalPhoneMessage', gameJournalEntryState.Inactive, gameJournalNotifyOption.Notify)
    end
    style.tooltip("Deactivate message, so it can be sent again")

    style.sectionHeaderEnd(true)
end

function apartment:drawTutorial()
    style.sectionHeaderStart("TUTORIAL")

    if not self.maxTutorialPropertyWidth then
        self.maxTutorialPropertyWidth = utils.getTextMaxWidth({ "Video Path", "Video Message", "Entrance Position" }) + 4 * ImGui.GetStyle().ItemSpacing.x
    end

    style.mutedText("Enable Tutorial:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(self.maxTutorialPropertyWidth)
    self.tutorialEnabled, changed = ImGui.Checkbox("##tutorialEnabled", self.tutorialEnabled)
    if changed then self.project:save() end
    style.tooltip("If enabled, a tutorial popup will be shown when the apartment is entered for the first time.\nThe popup will contain a video and a message.")
    ImGui.SameLine()
    ImGui.PushID("tutorialReset")
    if style.buttonNoBG(IconGlyphs.Reload) then
        Game.GetQuestsSystem():SetFactStr(self.purchasedFact .. "_tutorial", 0)
    end
    ImGui.PopID()
    style.tooltip("Reset, so that the tutorial will be shown again when the apartment is entered next time.")

    if self.tutorialEnabled then
        style.mutedText("Video Path:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxTutorialPropertyWidth)
        style.setNextItemWidth(250)
        self.apartmentVideo, changed = ImGui.InputTextWithHint('##apartmentVideo', 'base\\apartment\\intro.bk2', self.apartmentVideo, 250)
        if changed then self.project:save() end
        style.tooltip("Path to the video that will be played when the apartment is entered for the first time.")

        style.mutedText("Video Message:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxTutorialPropertyWidth)
        style.setNextItemWidth(250)
        self.tutorialLocKey, changed = ImGui.InputTextWithHint('##tutorialLocKey', 'LocKey#88888', self.tutorialLocKey, 250)
        if changed then self.project:save() end
        style.tooltip("LocKey for the text which will be displayed together with the tutorial video.")

        style.mutedText("Entrance Position:")
        ImGui.SameLine()
        ImGui.SetCursorPosX(self.maxTutorialPropertyWidth)
        self.apartmentEntrancePosition, _, finished = self.mod.baseUI.interactionUI.drawPosition(self.apartmentEntrancePosition, "entrance")
        if finished then
            self.project:save()
        end
        ImGui.SameLine()
        style.mutedText(IconGlyphs.HelpCircleOutline)
        style.tooltip("Position inside the apartment entrance, used to trigger the initial tutorial popup.")
    end

    style.sectionHeaderEnd()
end

function apartment:draw()
    if self.isTablet then
        workspot.draw(self)
    end

    self:drawBase()
    self:drawPurchaseTerminal()
    self:drawPositions()
    self:drawMedia()
    self:drawTutorial()

    if ImGui.Button("Reset All") then
        self:reset()
    end
    style.tooltip("Resets apartment purchase state, removes key item, resets mappins, refunds money and resets tutorial")
end

function apartment:save()
    local data = workspot.save(self)

    data.isTablet = self.isTablet
    data.tabletRef = self.tabletRef
    data.terminalRef = self.terminalRef
    data.apartmentName = self.apartmentName
    data.apartmentPurchasePosition = utils.deepcopy(self.apartmentPurchasePosition)
    data.apartmentPurchasedPosition = utils.deepcopy(self.apartmentPurchasedPosition)
    data.apartmentEntrancePosition = utils.deepcopy(self.apartmentEntrancePosition)
    data.apartmentKeyTDBID = self.apartmentKeyTDBID
    data.purchasedFact = self.purchasedFact
    data.enablePurchaseFact = self.enablePurchaseFact
    data.cost = self.cost
    data.useCustomKey = self.useCustomKey
    data.useIconRecord = self.useIconRecord
    data.apartmentPictureRecord = self.apartmentPictureRecord
    data.apartmentPictureAtlas = self.apartmentPictureAtlas
    data.apartmentPicturePart = self.apartmentPicturePart
    data.apartmentVideo = self.apartmentVideo
    data.messageLocKey = self.messageLocKey
    data.tutorialLocKey = self.tutorialLocKey
    data.tutorialEnabled = self.tutorialEnabled

    return data
end

return apartment