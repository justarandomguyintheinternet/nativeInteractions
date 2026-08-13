local utils = require("modules/utils/utils")
local resourceHelper = require("modules/utils/resourceHelper")
local config = require("modules/utils/config")

---@class apartmentManager
---@field apartments apartment[]
local apartmentManager = {
    apartments = {}
}

function apartmentManager.init()
    ObserveAfter("WorldMapTooltipController", "SetData", function(this, data, menu)
        if not data or not data.mappin then return end

        for _, apartment in pairs(apartmentManager.apartments) do
            if data.mappin:GetVariant() == gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant and data.mappin:GetWorldPosition():Distance(ToVector4(apartment.apartmentPurchasePosition)) < 0.05 then
                InkImageUtils.RequestSetImage(this, this.linkImage, apartment:getIconTDBID(), "OnIconCallback")
                inkTextRef.SetText(this.titleText, GetLocalizedText(apartment.apartmentName))
                local textParams = inkTextParams.new()
                textParams:AddNumber("price", apartment.cost)
                this.descText:SetText(GetLocalizedText("LocKey#93557"), textParams)
            end
        end
    end)
end

function apartmentManager.loadHookPatches()
    local key = 1
    local tmp = require("modules/classes/interactions/apartment"):new(nil, nil) -- Temporary instance to access getIconTDBID logic

    for _, file in pairs(dir("projects")) do
        if file.name:match("^.+(%..+)$") == ".json" then
            local project = config.loadFile(string.format("projects/%s", file.name))

            for _, interactionData in pairs(project.interactions or {}) do
                if interactionData.modulePath ~= "interactions/apartment" then
                    goto continue
                end

                if interactionData.messageLocKey ~= "" then
                    tmp.purchasedFact = interactionData.purchasedFact
                    tmp.useIconRecord = interactionData.useIconRecord
                    tmp.apartmentPictureRecord = interactionData.apartmentPictureRecord
                    local imageId = tmp:getIconTDBID()

                    resourceHelper.registerJournalPatch({
                        getID = function ()
                            return interactionData.purchasedFact
                        end,
                        patches = {
                            ["contacts/muamar_el_capitan_reyes/apartments"] = {
                                getEntry = function ()
                                    local message = gameJournalPhoneMessage.new()
                                    message.id = interactionData.purchasedFact
                                    message.text = ToLocalizationString(interactionData.messageLocKey)
                                    message.imageId = imageId
                                    return message
                                end
                            }
                        }
                    }, key)

                    key = key + 1
                end

                ::continue::
            end
        end
    end
end

function apartmentManager.addApartment(apartment)
    table.insert(apartmentManager.apartments, apartment)

    if apartment.messageLocKey ~= "" then
        apartmentManager.registerJournalPatch(apartment)
    end
end

function apartmentManager.removeApartment(apartment)
    utils.removeItem(apartmentManager.apartments, apartment)
    apartmentManager.removeJournalPatch(apartment)
end

---@param apartment apartment
function apartmentManager.registerJournalPatch(apartment)
    resourceHelper.registerJournalPatch(apartment:getJournalPatch(), apartment.choiceUniqueID)
end

---@param apartment apartment
function apartmentManager.removeJournalPatch(apartment)
    resourceHelper.removeJournalPatch(apartment.choiceUniqueID)
end

return apartmentManager