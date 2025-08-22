local utils = require("modules/utils/utils")
local resourceHelper = require("modules/utils/resourceHelper")

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

function apartmentManager.addApartment(apartment)
    table.insert(apartmentManager.apartments, apartment)

    if apartment.messageLocKey ~= "" then
        resourceHelper.registerJournalPatch(apartment:getJournalPatch(), apartment.choiceUniqueID)
    end
end

function apartmentManager.removeApartment(apartment)
    utils.removeItem(apartmentManager.apartments, apartment)
    resourceHelper.removeJournalPatch(apartment.choiceUniqueID)
end

return apartmentManager